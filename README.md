# ApiHammer

[![Build Status](https://travis-ci.org/notEthan/api_hammer.svg?branch=master)](https://travis-ci.org/notEthan/api_hammer)

a collection of little tools I have used when creating APIs. these are generally too small to have their own 
library, so have been collected here. 

## ApiHammer::Rails

A module for inclusion in a Rails application controller inheriting from ActionController::Base (Rocketpants 
should also work, but no guarantees). 

### #halt

You know that pattern in rails, `render(some_stuff) and return`? 

Don't use it. It's wrong. `and` is used to short-circuit, but you don't actually want your `return` to be conditional on the `render`. Since it is conditional on the return value of `render`, if the return value of `render` is false-ish (`false` or `nil`), you may end end up failing to return. The actual return value of `render` is undocumented. If you follow all the control paths that can affect the return value, last time I looked there were 37 different paths. None of them returns false, but if any control path changes to return false then `render and return` will break. 

What you really mean is `render(some_stuff); return`, but semicolons are (rightly) frowned upon 
in ruby. Really you should just put the `return` on the next line. 

Or, use `#halt`, kindly provided by ApiHammer.

`ApiHammer#halt` is based on the Sinatra pattern of `throw(:halt, response)`. It uses exceptions because Rails has baked-in exception rescuing (but not, at least as far as I have found, throw catching), but that is hidden away. 

### #check_required_params

Pass it an parameters which are required, and if they are missing or incorrect it will halt with 422 (not 400 - 400 is wrong). 

## Other

Various other things. This readme is incomplete and will be updated soon. 
