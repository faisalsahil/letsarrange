class Communication::ApplicationController < ActionController::Base
	protect_from_forgery only: [:delete]
end