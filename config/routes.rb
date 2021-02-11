Rails.application.routes.draw do

  get  'cards/last'
  post 'cards/snap'
  post 'cards/confirm'
  post 'cards/remove_patient'

  root 'cards#archive'
end
