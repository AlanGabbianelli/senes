class FitbitApiController < ApplicationController

  # before_filter :authenticate_user!

  def data_request
    client = current_user.fitbit_client
    case params[:resource]
    when 'activities'; output = client.activities_on_date(params[:date])
    when 'sleep'; output = client.heart_rate_on_date(params[:date])
    when 'activities/steps'; output = client.steps_on_date(params[:date])
    end
    render json: output
  end

  def heart
    devise_id = params[:id]
    user = User.find_by(id: devise_id)
    client = user.fitbit_client
    output = client.heart_rate_on_date('today')
    parsed = output['activities-heart'][0]['value']['restingHeartRate']
    render json: { 'restingHeartRate': parsed }
  end

  def sleep
    client = @user.fitbit_client
    output = client.sleep_logs_on_date('today')
    parsed = output['summary']['totalMinutesAsleep']
    render json: { 'totalMinutesAsleep': parsed }
  end

  def steps
    client = @user.fitbit_client
    output = client.steps_on_date('today')
    parsed = output['activities-steps'][0]['value']
    render json: { 'steps': parsed }
  end

  def battery
    client = @user.fitbit_client
    output = client.device_info
    parsed = output[0]['battery']
    render json: { 'battery': parsed }
  end

  def last_sync_time
    client = @user.fitbit_client
    output = client.device_info
    parsed = output[0]['lastSyncTime']
    render json: { 'lastSyncTime': parsed }
  end

  def name
    client = @user.fitbit_client
    output = client.name
    puts output
    parsed_name = output['user']['fullName']
    parsed_avatar = output['user']['avatar']
    render json: { 'userName': parsed_name, 'avatar': parsed_avatar }
  end

  # def sedentary
  #   client = @user.fitbit_client
  #   output = client.activity_level('today')
  #   parsed = output['summary']['sedentaryMinutes']
  #   render json: { 'sedentaryMinutes': parsed }
  # end

  # def lightly_active
  #   client = @user.fitbit_client
  #   output = client.activity_level('today')
  #   parsed = output['summary']['lightlyActiveMinutes']
  #   render json: { 'lightlyActiveMinutes': parsed }
  # end
  #
  # def fairly_active
  #   client = @user.fitbit_client
  #   output = client.activity_level('today')
  #   parsed = output['summary']['fairlyActiveMinutes']
  #   render json: { 'fairlyActiveMinutes': parsed }
  # end
  #
  # def very_active
  #   client = @user.fitbit_client
  #   output = client.activity_level('today')
  #   parsed = output['summary']['veryActiveMinutes']
  #   render json: { 'veryActiveMinutes': parsed }
  # end

  def overall
    devise_id = params[:id]
    @user = User.find_by(id: devise_id)
    client = @user.fitbit_client
    device_info_output = client.device_info
    battery_parsed = device_info_output[0]['battery']
    last_sync_time_parsed = device_info_output[0]['lastSyncTime']
    heart_output = client.heart_rate_on_date('today')
    heart_parsed = heart_output['activities-heart'][0]['value']['restingHeartRate']
    sleep_output = client.sleep_logs_on_date('today')
    sleep_parsed = sleep_output['summary']['totalMinutesAsleep']
    sleep_formatted = format_sleep(sleep_parsed)
    steps_output = client.steps_on_date('today')
    steps_parsed = steps_output['activities-steps'][0]['value']
    name_output = client.name
    name_parsed = name_output['user']['fullName']
    avatar_parsed = name_output['user']['avatar']
    # activity_output = client.activity_level('today')
    # sedentary_parsed = activity_output['summary']['sedentaryMinutes']
    # lightly_active_parsed = activity_output['summary']['lightlyActiveMinutes']
    # fairly_active_parsed = activity_output['summary']['fairlyActiveMinutes']
    # very_active_parsed = activity_output['summary']['veryActiveMinutes']
    status = bad_ok_good_status(heart_parsed, sleep_parsed, steps_parsed)
    @json = {
      'battery': battery_parsed,
      'lastSyncTime': last_sync_time_parsed,
      'restingHeartRate': heart_parsed,
      'totalMinutesAsleep': sleep_formatted,
      'steps': steps_parsed,
      # 'sedentaryMinutes': sedentary_parsed,
      # 'lightlyActiveMinutes': lightly_active_parsed,
      # 'fairlyActiveMinutes': fairly_active_parsed,
      # 'veryActiveMinutes': very_active_parsed,
      'status': status,
      'name': name_parsed,
      'avatar': avatar_parsed
    }
    render json: @json
  end

  def format_sleep(mins)
    hours = mins / 60
    mins = mins % 60
    return "#{hours}h, #{mins}m"
  end

  def heart_evaluator(heart_rate)
    if heart_rate == nil
      return 1
    elsif heart_rate <= 40 || heart_rate >= 100
      return 0
    elsif heart_rate >= 50 && heart_rate <= 80
      return 2
    else
      return 1
    end
  end

  def sleep_evaluator(sleep_mins)
    if sleep_mins < 300
      return 0
    elsif sleep_mins < 360
      return 1
    else
      return 2
    end
  end

  def steps_evaluator(steps)
    steps = steps.to_i
    if steps < 2000
      return 0
    elsif steps < 3000
      return 1
    else
      return 2
    end
  end

  def bad_ok_good_status(heart_parsed, sleep_parsed, steps_parsed)
    result = heart_evaluator(heart_parsed) + sleep_evaluator(sleep_parsed) + steps_evaluator(steps_parsed)
    if result <= 2
      return 'not great'
    elsif result <= 4
      return 'ok'
    else
      return 'great'
    end
  end

  def set_alarm
    devise_id = params[:id]
    time = params[:time]
    client = User.find_by(id: devise_id).fitbit_client
    tracker_id = client.device_info[0]['id']
    response = client.post_alarm(tracker_id, time)
    render json: { 'response': response }
  end

  def alarms
    devise_id = params[:id]
    client = User.find_by(id: devise_id).fitbit_client
    tracker_id = client.device_info[0]['id']
    response = client.get_alarms(tracker_id)['trackerAlarms']
    render json: { 'trackerAlarms': response }
  end

  def tracker_id
    devise_id = params[:id]
    client = User.find_by(id: devise_id).fitbit_client
    response = client.device_info[0]['id']
    render json: { 'trackerId': response }
  end
end
