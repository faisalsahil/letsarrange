module InTmz
  def attrs_in_tmz(*attrs)
    attrs.each do |attr|
      define_method "#{ attr }_in_tmz" do
        send(attr).try(:in_time_zone, time_zone)
      end
    end
  end
end