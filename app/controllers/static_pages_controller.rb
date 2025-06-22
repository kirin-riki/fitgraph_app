class StaticPagesController < ApplicationController
  def top
    Rails.logger.info "=== Favicon Debug ==="
    Rails.logger.info "User Agent: #{request.user_agent}"
    Rails.logger.info "Request Path: #{request.path}"
    Rails.logger.info "Request Format: #{request.format}"
    Rails.logger.info "===================="
  end
end
