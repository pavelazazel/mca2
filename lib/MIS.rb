class MIS
  require "#{Rails.root}/lib/patient.rb"
  require 'net/http'
  require 'uri'

  def initialize(url: url, user: user, password: password)
    @url = url
    @user = user
    @password = password
    @key = sign_in
  end

  def patient(pin)
    pin = pin.encode('windows-1251', 'UTF-8')
    data = "USER=#{@user}&PASSWORD=#{@key}&RULL=%CD%C0%C9%D2%C8&PIN=#{pin}"
    html = request(@url, data).encode('UTF-8', 'windows-1251')
    patient = extract_patient(html)
  end


  private

  def sign_in
    data = "COMMAND=100&USER=#{@user}&PASSWORD=#{@password}"
    extract_data(request(@url, data), 'PASSWORD', '([0-9a-z]+)')
  end

  def request(url, data)
    uri = URI.parse(@url)
    http = Net::HTTP.new(uri.host, uri.port)
    req = Net::HTTP::Post.new(uri.request_uri)
    req.body = data
    http.request(req).body
  end

  def extract_patient(html)
    patient = Patient.new(pin: extract_data(html, 'PININFO', '([А-Я]{4}\s?\d{4,6})'),
                      surname: extract_data(html, 'SURNAMEINFO', '([А-Я]+)'),
                        name1: extract_data(html, 'NAME1INFO', '([А-Я]+)'),
                        name2: extract_data(html, 'NAME2INFO', '([А-Я]+)'),
                           dr: extract_data(html, 'DRINFO', '(\d{2}[\.\/]\d{2}[\.\/]\d{4})')
                           )
  end

  def extract_data(html, name_attr, regexp_str)
    regexp = Regexp.new("<INPUT TYPE=\"hidden\" name=\"#{name_attr}\" value=\"#{regexp_str}\">")
    if html.match?(regexp)
      html.match(regexp)[1]
    else
      ''
    end
  end
end