
import { application } from "./application"
import HelloController     from "./hello_controller"
import DropdownController  from "./dropdown_controller"

application.register("hello",    HelloController)
application.register("dropdown", DropdownController)

window.Stimulus = application
