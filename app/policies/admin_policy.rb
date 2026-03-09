# Policy for admin namespace access
class AdminPolicy < Struct.new(:user, :admin)
  def access?
    user&.admin? || user&.unit_lead?
  end
end
