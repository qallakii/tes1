import { Application } from "@hotwired/stimulus"

const application = Application.start()

// Configure Stimulus development experience
application.debug = false
window.Stimulus   = application

export { application }
//= require rails-ujs
//= require activestorage
//= require turbolinks
//= require_tree .
