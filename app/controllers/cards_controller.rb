class CardsController < ApplicationController
  require "#{Rails.root}/lib/MIS.rb"
  require "#{Rails.root}/lib/patient.rb"
  protect_from_forgery except: [:snap, :confirm, :remove_patient, :last]

  def archive
    @cards = Card.order(id: :desc).first(5)
  end

  def snap
    path_to_img = "#{Rails.root}/tmp/snapshot.jpeg"
    image_data = Base64.decode64(params[:img]['data:image/jpeg;base64,'.length .. -1].gsub(' ', '+'))
    File.open(path_to_img, 'wb') { |f| f.write image_data }
    text = recognize(path_to_img)
    if params[:ready] == 'true'
      pin = pin(text)
      unless pin.nil?
        patient = patient(pin)
        add_patient(patient, params[:box]) if patient.check(text)
        response = patient if patient.found?
      end
    else
      response = '{ "next" : "true" }' if next?(text)
    end
    respond_to do |format|
      format.json { render json: response }
    end
  end

  def confirm
    add_patient(patient(params[:pin]), params[:box])
  end

  def remove_patient
    Card.find_by({ pin: params[:pin], box: params[:box] }).destroy
  end

  def last
    respond_to do |format|
      format.json { render json: Card.order(id: :desc).first(5) }
    end
  end


  private

  def patient(pin)
    # TODO: при каждом запросе аутентификация в мис проходит заново. надо это исправить (мб @key в куки?)
    mis = MIS.new(url: ENV['MIS_URL'], user: ENV['MIS_USER'], password: ENV['MIS_PASSWORD'])
    patient = mis.patient(pin)
  end

  def add_patient(patient, box)
    card = Card.new
    card.attributes = { name: patient.surname + ' ' +
                              patient.name1 + ' ' +
                              patient.name2,
                         pin: patient.pin,
                          dr: patient.dr,
                         box: box
                      }
    card.save
  end

  def recognize(path_to_img)
    RTesseract.new(path_to_img, lang: 'rus').to_s
  end

  def pin(text)
    regexp = /[А-Я]{4}\s?\d{4,6}/
    pin = text.match(regexp)
    pin[0].gsub(' ', '') unless pin.nil?
  end

  def next?(text)
    text.include? 'СЛЕДУЮЩИЙ'
  end
end
