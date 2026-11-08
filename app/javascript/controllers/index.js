// Import and register controllers lazily from the importmap via controllers/**/*_controller.
// Lazy loading defers each controller module until a matching data-controller appears,
// reducing unused JavaScript on pages that don't use every controller.
import { application } from "controllers/application"
import { lazyLoadControllersFrom } from "@hotwired/stimulus-loading"
lazyLoadControllersFrom("controllers", application)
