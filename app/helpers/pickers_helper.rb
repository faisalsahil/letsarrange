module PickersHelper
  def picker_title field
    case field.to_sym
    when :finish_by
      "Must finish by?"
    when :earliest_start
      "Earliest time to start?"
    when :ideal_start
      "Best time to start?"
    when :length
      "Length of appointment?"
    end
  end
end