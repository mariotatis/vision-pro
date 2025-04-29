import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="file-upload"
export default class extends Controller {
  static targets = ["input", "preview", "imagePreview", "fileInfo", "uploadButton", "uploadText", "spinner"]

  connect() {
    console.log("File upload controller connected")
    this.toggleUploadButton()
  }

  preview() {
    const file = this.inputTarget.files[0]
    
    if (file) {
      this.previewTarget.classList.remove('hidden')
      
      if (file.type.startsWith('image/')) {
        this.imagePreviewTarget.classList.remove('hidden')
        const reader = new FileReader()
        reader.onload = (e) => {
          this.imagePreviewTarget.src = e.target.result
        }
        reader.readAsDataURL(file)
      } else {
        this.imagePreviewTarget.classList.add('hidden')
      }
      
      this.fileInfoTarget.textContent = `${file.name} (${(file.size / 1024).toFixed(2)} KB)`
    } else {
      this.previewTarget.classList.add('hidden')
    }
    
    this.toggleUploadButton()
  }

  startUpload() {
    this.uploadTextTarget.textContent = 'Uploading...'
    this.spinnerTarget.classList.remove('hidden')
  }
  
  toggleUploadButton() {
    const file = this.inputTarget.files[0]
    if (file) {
      this.uploadButtonTarget.disabled = false
      this.uploadButtonTarget.classList.remove('opacity-50', 'cursor-not-allowed', 'bg-gray-400')
      this.uploadButtonTarget.classList.add('bg-blue-500', 'hover:bg-blue-600')
    } else {
      this.uploadButtonTarget.disabled = true
      this.uploadButtonTarget.classList.add('opacity-50', 'cursor-not-allowed', 'bg-gray-400')
      this.uploadButtonTarget.classList.remove('bg-blue-500', 'hover:bg-blue-600')
    }
  }
}
