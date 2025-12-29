# frozen_string_literal: true

class CalendarPolicy < ApplicationPolicy
  def show?
    true
  end

  def ical?
    true
  end
end
