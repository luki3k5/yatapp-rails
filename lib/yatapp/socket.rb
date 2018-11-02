require 'faye/websocket'
require 'eventmachine'
require 'yatapp/inbox'
require 'json'
require 'cgi'
require 'uri'
begin
  require 'rails-i18n'
rescue
  puts "WARNING: Failed to require rails-i18n gem, websocket integration may fail."
end

module Phoenix
  class Socket
    include MonitorMixin
    attr_reader :path, :socket, :inbox, :topic
    attr_accessor :verbose, :join_options_proc, :connect_options_proc
    attr_accessor *Yatapp::Configuration::CONFIGURATION_OPTIONS

    def initialize
      initialize_configuration
      @path = "wss://run.yatapp.net/socket/websocket?api_token=#{api_access_token}"
      @topic = "translations:#{project_id}"
      @join_options = {}
      @connect_options = {}
      @inbox = Phoenix::Inbox.new(ttl: 15)
      super() # MonitorMixin
      @inbox_cond = new_cond
      @thread_ready = new_cond
      @topic_cond = new_cond
      reset_state_conditions
      request_reply(event: "ping", payload: {})
    end

    def request_reply(event:, payload: {}, timeout: 5) # timeout in seconds
      ref = SecureRandom.uuid
      synchronize do
        ensure_connection
        @topic_cond.wait_until { @topic_joined }
        EM.next_tick { socket.send({ topic: topic, event: event, payload: payload, ref: ref }.to_json) }
        log [event, ref]

        # Ruby's condition variables only support timeout on the basic 'wait' method;
        # This should behave roughly as if wait_until also support a timeout:
        # `inbox_cond.wait_until(timeout) { inbox.key?(ref) || @dead }
        #
        # Note that this serves only to unblock the main thread, and should not halt execution of the
        # socket connection. Therefore, there is a possibility that the inbox may pile up with
        # unread messages if a lot of timeouts are encountered. A self-sweeping inbox will
        # be implemented to prevent this.
        ts = Time.now
        loop do
          inbox_cond.wait(timeout) # waits until time expires or signaled
          break if inbox.key?(ref) || @dead
          raise 'timeout' if timeout && Time.now > (ts + timeout)
        end
        inbox.delete(ref) { raise "reply #{ref} not found" }
      end
    end

    def join_options
      return @join_options unless join_options_proc
      join_options_proc.call(@join_options)
    end

    def connect_options
      return @connect_options unless connect_options_proc
      connect_options_proc.call(@connect_options)
    end

    private

    attr_reader :inbox_cond, :thread_ready

    def initialize_configuration
      options = Yatapp.options
      Yatapp::Configuration::CONFIGURATION_OPTIONS.each do |key|
        send("#{key}=", options[key])
      end
    end

    def log(msg)
      return unless @verbose
      puts "[#{Thread.current[:id]}] #{msg} (#@topic_joined)"
    end

    def ensure_connection
      connection_alive? or synchronize do
        spawn_thread
        thread_ready.wait(3)
        if @dead
          @spawned = false
          raise 'dead connection timeout'
        end
      end
    end

    def connection_alive?
      @ws_thread&.alive? && !@dead
    end

    def reset_state_conditions
      @dead = true # no EM thread active, or the connection has been closed
      @socket = nil # the Faye::Websocket::Client instance
      @spawned = false # The thread running (or about to run) EventMachine has been launched
      @join_ref = SecureRandom.uuid # unique id that Phoenix uses to identify the socket <-> channel connection
      @topic_joined = false # The initial join request has been acked by the remote server
    end

    def add_new_key_to_i18n(key, values)
      values.each do |value|
        unless I18n.available_locales.include?(value['lang'].to_sym)
          add_new_locale(value['lang'])
        end

        key_array = key.split(".")
        translation_hash = key_array.reverse.inject(value['text']) {|acc, n| {n => acc}}
        I18n.backend.store_translations(value['lang'].to_sym, translation_hash)
        puts "new translation added: #{value['lang']} => #{key}: #{value['text']}"
      end
    end

    def add_new_locale(lang)
      existing_locales = I18n.config.available_locales
      new_locales      = existing_locales << lang.to_sym
      I18n.config.available_locales = new_locales.uniq
    end

    def handle_message(event)
      data = JSON.parse(event.data)
      log event.data
      synchronize do
        if data['event'] == 'phx_close'
          log('handling close from message')
          handle_close(event)
        elsif data['event'] == 'new_translation'
          payload = data['payload']
          add_new_key_to_i18n(payload['key'], payload['values'])
        elsif data['event'] == 'updated_translation'
          payload = data['payload']
          add_new_key_to_i18n(payload['new_key'], payload['values'])
        elsif data['event'] == 'deleted translation'
          puts 'deleted translation'
        elsif data['ref'] == @join_ref && data['event'] == 'phx_error'
          # NOTE: For some reason, on errors phx will send the join ref instead of the message ref
          inbox_cond.broadcast
        elsif data['ref'] == @join_ref
          log ['join_ref', @join_ref]
          @topic_joined = true
          @topic_cond.broadcast
        else
          inbox[data['ref']] = data
          inbox_cond.broadcast
        end
      end
    end

    def handle_open(event)
      log 'open'
      socket.send({ topic: topic, event: "phx_join", payload: join_options, ref: @join_ref, join_ref: @join_ref }.to_json)
      synchronize do
        @dead     = false
        thread_ready.broadcast
      end
      Yatapp.download_translations
    end

    def handle_close(event)
      synchronize do
        reset_state_conditions
        inbox_cond.signal
        thread_ready.signal
      end
    end

    def build_path
      uri = URI.parse(path)
      existing_query = CGI.parse(uri.query || '')
      uri.query = URI.encode_www_form(existing_query.merge(connect_options))
      uri.to_s
    end

    def spawn_thread
      return if @spawned || connection_alive?
      log 'spawning...'
      @spawned = true
      @ws_thread = Thread.new do
        Thread.current[:id] = "WSTHREAD_#{SecureRandom.hex(3)}"
        run_event_machine
      end
    end

    def reconnect
      @spawned = true
      @ws_thread = Thread.new do
        Thread.current[:id] = "WSTHREAD_#{SecureRandom.hex(3)}"
        run_event_machine
      end
    end

    def run_event_machine
      EM.run do
        synchronize do
          log 'em.run.sync'
          @socket = Faye::WebSocket::Client.new(build_path)
          socket.on :open do |event|
            handle_open(event)
          end

          socket.on :message do |event|
            handle_message(event)
          end

          socket.on :close do |event|
            log [:close, event.code, event.reason]
            handle_close(event)
            EM.tick_loop do
              unless connection_alive?
                spawn_thread
                sleep(1)
              else
                EM.next_tick { socket.send({ topic: "translations:#{project_id}", event: "ping", payload: {}, ref: @join_ref }.to_json) }
              end
            end
          end

          EventMachine.add_periodic_timer(50) do
            EM.next_tick { socket.send({ topic: "translations:#{project_id}", event: "ping", payload: {}, ref: @join_ref }.to_json) }
          end
        end
      end
    end
  end
end
