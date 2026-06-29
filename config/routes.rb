Rails.application.routes.draw do
  get  "contact", to: "contacts#new",    as: :contact
  post "contact", to: "contacts#create"

  get "up" => "rails/health#show", as: :rails_health_check

  root "contacts#new"
end
