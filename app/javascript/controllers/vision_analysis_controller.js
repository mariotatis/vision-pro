import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="vision-analysis"
export default class extends Controller {
  static targets = ["analyzeButton", "loadingSpinner", "analysisSection"]
  static values = { mediumId: Number }

  connect() {
    console.log("Vision analysis controller connected")
    
    // If we have the analyze button and no results yet, trigger analysis automatically
    if (this.hasAnalyzeButtonTarget && document.getElementById('autoAnalyzeButton')) {
      // Automatically trigger analysis after a short delay
      setTimeout(() => {
        this.triggerAutoAnalysis()
      }, 500) // Short delay to ensure everything is loaded
    }
    
    // If loading spinner is visible, start polling for results
    if (this.hasLoadingSpinnerTarget && 
        !this.loadingSpinnerTarget.classList.contains('hidden')) {
      this.startPolling()
    }
  }

  triggerAutoAnalysis() {
    console.log("Auto-triggering analysis")
    
    // Disable the button to prevent multiple submissions
    if (this.hasAnalyzeButtonTarget) {
      this.analyzeButtonTarget.disabled = true
    }
    
    // Submit the form programmatically
    document.getElementById('autoAnalyzeButton').closest('form').submit()
    
    // Start polling for results
    this.startPolling()
  }
  
  startAnalysis(event) {
    // This is kept for compatibility but shouldn't be called anymore
    if (event) {
      event.preventDefault()
    }
    
    // Show loading spinner
    if (this.hasLoadingSpinnerTarget) {
      this.loadingSpinnerTarget.classList.remove('hidden')
    }
    
    // Disable the button
    if (this.hasAnalyzeButtonTarget) {
      this.analyzeButtonTarget.disabled = true
    }
    
    // If triggered by an event, submit the form
    if (event && event.target) {
      event.target.closest('form').submit()
    }
    
    // Start polling for results
    this.startPolling()
  }
  
  startPolling() {
    console.log("Starting polling for results")
    // Set a timeout to refresh the page after 5 seconds
    // This gives the background job time to process the image
    setTimeout(() => {
      window.location.reload()
    }, 5000)
  }
}
