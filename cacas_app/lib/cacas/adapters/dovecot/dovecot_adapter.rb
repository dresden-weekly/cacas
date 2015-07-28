class DovecotAdapter < CacasAdapter

  class << self
    def create_new_user user
      Rails.logger.info "DovecotAdapter processing #{user} for user #{user.user__firstname}"
      user
    end

    def created_new_user event
      event
    end
  end
end
