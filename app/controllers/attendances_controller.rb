# frozen_string_literal: true

# Attendance display controller
class AttendancesController < ApplicationController
  def index
    @attendance = Attendance.order(created_at: :desc)
  end
end
