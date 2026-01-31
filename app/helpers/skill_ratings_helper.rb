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
end
