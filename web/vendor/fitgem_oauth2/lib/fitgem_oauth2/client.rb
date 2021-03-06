require 'fitgem_oauth2/activity.rb'
require 'fitgem_oauth2/device_info.rb'
require 'fitgem_oauth2/heart.rb'
require 'fitgem_oauth2/activity_level.rb'
require 'fitgem_oauth2/sleep.rb'
require 'fitgem_oauth2/steps.rb'
require 'fitgem_oauth2/alarm.rb'
require 'fitgem_oauth2/name.rb'

require 'base64'
require 'faraday'

module FitgemOauth2
  class Client

    attr_reader :token

    attr_reader :user_id

    attr_reader :client_id

    attr_reader :client_secret

    def initialize(opts)
      @client_id = opts[:client_id]
      if @client_id.nil?
        puts "TODO. Raise an exception due to missing client id"
      end

      @client_secret = opts[:client_secret]
      if @client_secret.nil?
        puts "TODO. Raise an exception due to missing client secret"
      end

      @token = opts[:token]
      if @token.nil?
        puts "TODO. Raise an exception due to missing token"
      end

      @user_id = opts[:user_id]
      if @user_id.nil?
        puts "TODO. Raise an exception due to missing fitbit user id"
      end

      @connection = Faraday.new("https://api.fitbit.com")
    end

    def get_call(url)
      response = connection.get(url)  do |request|
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Content-Type'] = "application/x-www-form-urlencoded"
      end
      JSON.parse(response.body).merge!(response.headers)
    end

    def post_call(url)
      response = connection.post(url)  do |request|
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Content-Type'] = "application/x-www-form-urlencoded"
      end
      JSON.parse(response.body).merge!(response.headers)
    end

    def delete_call(url)
      response = connection.delete(url)  do |request|
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Content-Type'] = "application/x-www-form-urlencoded"
      end
    end

    def get_call_array(url)
      response = connection.get(url)  do |request|
        request.headers['Authorization'] = "Bearer #{token}"
        request.headers['Content-Type'] = "application/x-www-form-urlencoded"
      end
      JSON.parse(response.body)
    end

    def refresh_access_token(refresh_token)
      response = connection.post('/oauth2/token') do |request|
        encoded = Base64.strict_encode64("#{@client_id}:#{@client_secret}")
        request.headers['Authorization'] = "Basic #{encoded}"
        request.headers['Content-Type'] = "application/x-www-form-urlencoded"
        request.params['grant_type'] = "refresh_token"
        request.params['refresh_token'] = refresh_token
      end
      response.body
    end

    private

    attr_accessor :connection

    def format_date(date)
      date
    end

    def get(url)

    end

    def raw_get(url)
    end

  end
end
