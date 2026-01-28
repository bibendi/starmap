# Helper methods for skill ratings views
module SkillRatingsHelper
  # Rating level helpers
  def rating_level_label(rating)
    case rating
    when 0 then "Не имею представления"
    when 1 then "Имею представление"
    when 2 then "Свободно владею"
    when 3 then "Могу учить других"
    else "Неизвестно"
    end
  end

  def rating_level_short(rating)
    case rating
    when 0 then "Нет"
    when 1 then "Базовый"
    when 2 then "Продвинутый"
    when 3 then "Эксперт"
    else "?"
    end
  end

  def rating_level_description(rating)
    case rating
    when 0 then "Слышал об этом, но на практике не сталкивался. Нужен онбординг с нуля"
    when 1 then "Могу выполнять простые задачи под присмотром или в паре с коллегой"
    when 2 then "Могу самостоятельно взять задачу средней сложности и довести ее до production"
    when 3 then "Могу объяснить архитектурные решения, провести код-ревью и быть ментором"
    else ""
    end
  end

  # Rating color helpers
  def rating_color_classes(rating)
    case rating
    when 0 then "text-gray-600 bg-gray-50 border-gray-300"
    when 1 then "text-blue-600 bg-blue-50 border-blue-300"
    when 2 then "text-green-600 bg-green-50 border-green-300"
    when 3 then "text-purple-600 bg-purple-50 border-purple-300"
    else "text-gray-600 bg-gray-50 border-gray-300"
    end
  end

  def rating_badge_classes(rating)
    case rating
    when 0 then "bg-gray-100 text-gray-800"
    when 1 then "bg-blue-100 text-blue-800"
    when 2 then "bg-green-100 text-green-800"
    when 3 then "bg-purple-100 text-purple-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  # Status helpers
  def status_label(status)
    case status
    when "draft" then "Черновик"
    when "submitted" then "На утверждении"
    when "approved" then "Утверждена"
    when "rejected" then "Отклонена"
    else status
    end
  end

  def status_badge_classes(status)
    case status
    when "draft" then "bg-gray-100 text-gray-800"
    when "submitted" then "bg-yellow-100 text-yellow-800"
    when "approved" then "bg-green-100 text-green-800"
    when "rejected" then "bg-red-100 text-red-800"
    else "bg-gray-100 text-gray-800"
    end
  end

  def status_icon(status)
    case status
    when "draft" then "fa-edit"
    when "submitted" then "fa-clock"
    when "approved" then "fa-check-circle"
    when "rejected" then "fa-times-circle"
    else "fa-question"
    end
  end

  # Criticality helpers
  def criticality_label(criticality)
    case criticality
    when "high" then "Высокая"
    when "normal" then "Обычная"
    when "low" then "Низкая"
    else criticality
    end
  end

  def criticality_badge_classes(criticality)
    case criticality
    when "high" then "text-red-600 bg-red-50"
    when "normal" then "text-yellow-600 bg-yellow-50"
    when "low" then "text-green-600 bg-green-50"
    else "text-gray-600 bg-gray-50"
    end
  end

  # Trend helpers
  def trend_icon(trend)
    case trend
    when "improved" then "fa-arrow-up text-green-600"
    when "declined" then "fa-arrow-down text-red-600"
    when "stable" then "fa-minus text-gray-600"
    when "significant_change" then "fa-exchange-alt text-blue-600"
    else "fa-question text-gray-600"
    end
  end

  def trend_label(trend)
    case trend
    when "improved" then "Улучшение"
    when "declined" then "Снижение"
    when "stable" then "Без изменений"
    when "significant_change" then "Значительное изменение"
    else "Неизвестно"
    end
  end

  # Rating display helpers
  def rating_display(rating, show_description: false)
    content_tag :div, class: "rating-display" do
      concat content_tag(:span, rating, class: "rating-value #{rating_badge_classes(rating)} px-2 py-1 rounded text-sm font-semibold")
      concat content_tag(:span, rating_level_label(rating), class: "ml-2 text-sm text-gray-700")
      if show_description
        concat content_tag(:p, rating_level_description(rating), class: "mt-1 text-xs text-gray-500")
      end
    end
  end

  def rating_scale_display(rating, max_rating: 3)
    content_tag :div, class: "rating-scale-display flex items-center space-x-2" do
      (0..max_rating).each do |level|
        is_filled = rating >= level
        classes = if is_filled
          rating_color_classes(rating)
        else
          "text-gray-300 bg-white border-gray-200"
        end
        concat content_tag(:div, level, class: "w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold border-2 #{classes}")
      end
      concat content_tag(:span, rating_level_label(rating), class: "ml-2 text-sm font-medium text-gray-700")
    end
  end

  # Action button helpers
  def can_submit_rating?(skill_rating)
    policy(skill_rating).submit? && skill_rating.can_be_submitted?
  end

  def can_approve_rating?(skill_rating)
    policy(skill_rating).approve? && skill_rating.can_be_approved?
  end

  def can_reject_rating?(skill_rating)
    policy(skill_rating).reject? && skill_rating.can_be_rejected?
  end

  def can_edit_rating?(skill_rating)
    policy(skill_rating).edit? && skill_rating.can_be_edited?
  end
end
