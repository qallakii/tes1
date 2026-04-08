module ApplicationHelper
  def current_user
    @current_user ||= User.find_by(id: session[:user_id])
  end

  def logged_in?
    current_user.present?
  end

  def format_bytes(bytes)
    value = bytes.to_i
    units = %w[B KB MB GB TB]
    unit_index = 0

    while value >= 1024 && unit_index < units.length - 1
      value /= 1024.0
      unit_index += 1
    end

    unit_index.zero? ? "#{value.to_i} #{units[unit_index]}" : "#{format('%.1f', value)} #{units[unit_index]}"
  end
end
