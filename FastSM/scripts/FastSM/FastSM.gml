//# feather use syntax-errors
#macro FASTSM_ENABLE_VERSION    "v0.0.3"
#macro FASTSM_ENABLE_SAFETY     true
#macro FASTSM_ENABLE_WARNINGS   true
#macro FASTSM_ENABLE_LOGGING    true
#macro FASTSM_ERROR_LOGGER      throw
#macro FASTSM_WARN_LOGGER       show_debug_message
#macro FASTSM_LOG_LOGGER        show_debug_message

function FastSM(_size, _trigger_count) constructor {  
    //calling instance
    __owner = other;
    //amount of total states
    __size =            _size;
    __states =          array_create(__size, undefined);
    //internal, used for technicalk reasons
    __states[0] =       { name: "INTERNAL_state_not_a_state" }
    //index of currently active state
    __state_active =    0;
    __state_previous =  0;
    //amount of total triggers
    __trigger_count =   _trigger_count;
    __triggers =        array_create(__trigger_count, undefined);
    //default event map
    __default_events = 
    {
        enter: function() {},
        leave: function() {}
    };
    __default_events_keys = variable_struct_get_names(__default_events);
    //time the current state has been active for in microseconds
    __time = get_timer();
    
    /// @ignore
    /// @param {string} error message
    static __fastsm_error = function() {
        var _out = "[ERROR] FastSM\n";
        var i = -1; repeat(argument_count) { i++;
            _out += string(argument[i]);
        }
        FASTSM_ERROR_LOGGER(_out);
    };
    
    /// @ignore
    /// @param {string} error message
    static __fastsm_warn = function() {
        if (FASTSM_ENABLE_WARNINGS) {
            var _out = "[WARNING] FastSM::";
            var i = -1; repeat(argument_count) { i++;
                _out += string(argument[i]);
            }
            FASTSM_WARN_LOGGER(_out);
        }
    };
    
    /// @ignore
    /// @param {string} error message
    static __fastsm_log = function() {
        if (FASTSM_ENABLE_LOGGING) {
            var _out = "[LOG] FastSM::";
            var i = -1; repeat(argument_count) { i++;
                _out += string(argument[i]);
            }
            FASTSM_LOG_LOGGER(_out);
        }
    };
    
    
    //stolen from (Sohom Sahaun | @sohomsahaun)'s SnowState
    /// @ignore
    /// @param  {method}    method
    /// @returns {Bool} whether the supplied method is a method (true) or not (false)
    static __valid_method = function(_method) {
        try {
            return is_method(method(undefined, _method));
        } catch (_e) {
            return false;
        }
    };
    
    /// @ignore
    /// @param  {real}  state  id
    static __state_build = function(_id) {
        var _state = __states[_id];
        var _mask = 0x00;
        
        _state[$ "tags"] ??= noone;
        _state[$ "tags"] = is_array(_state[$ "tags"]) ? _state[$ "tags"] : [_state[$ "tags"]];
        
        var _mask = 0x00;
        if (_state[$ "tags"][0] == noone) {
            _mask = 0x00;
        }
        else if (_state[$ "tags"][0] == all) {
            _mask = 0x7FFFFFFFFFFFFFFF;
        } else {
            var i = -1; var n = array_length(_state[$ "tags"]); repeat( n ) { i++;
                _mask += 0x01<<(_state[$ "tags"][i])
            }
        }
        _state[$ "__mask"] = _mask;
        
        var i = -1; var n = array_length(__default_events_keys); repeat(n) { i++;
            var _event =    __default_events_keys[i];
            var _funct =    _state[$ _event] ?? __default_events[$ _event];
            
            _state[$ _event] = method(__owner, _funct);
        }
        __states[_id] = _state;
    }
    
    /// @ignore
    /// @param  {Real}  state   id
    static state_build = function(_id) {
        if (FASTSM_ENABLE_SAFETY) {
            if (__states[_id] == undefined) {
                __fastsm_warn(
                    "State with id\"",
                     string(_id), 
                    "\" has not been defined yet and cannot be built. Skipping."
                )
                return;
            }
            __fastsm_log(
                "BUILDING: State \"",
                __states[_id][$ "name"] ?? "id: " + string(_id) + " <unknown name, please provide a state name>",
                "\""
            )
        }
        __state_build(_id);
    }
    
    /// @param {Real}   state   id
    /// @param {Struct} state   struct {name: "", tags: [] or Tag, enter: function(this, previous), leave(this, next): function}
    /// @returns {Struct.FastSM}
    static state_add = function(_id, _state) {
        if (FASTSM_ENABLE_SAFETY) {
            if (!is_struct(_state)) {
                __fastsm_error(
                    "Expected state struct, got \"",
                    typeof(_state),
                    "\" instead."
                )
            }
            if (__states[_id] != undefined) {
                __fastsm_warn(
                    "State \"",
                    _state[$ "name"] ?? "id: " + string(_id) + " <unknown name, please provide a state name>", 
                    "\" has been defined already. The previous definition has been replaced."
                )
            }
        }
        
        __states[_id] = _state;
    }
    
    /// @ignore
    /// @param  {Real}  trigger id
    static __trigger_build = function(_id) {
        var _trigger = __triggers[_id];
        
        var _include = [];
        var _exclude = [];
        
        _trigger[$ "include"] ??= noone 
        if (!is_array(_trigger[$ "include"])) {
            _trigger[$ "include"] = [_trigger[$ "include"]];
        }
        _include = _trigger[$ "include"]; 
        
        _trigger[$ "exclude"] ??= noone 
        if (!is_array(_trigger[$ "exclude"])) {
            _trigger[$ "exclude"] = [_trigger[$ "exclude"]];
        }
        _exclude = _trigger[$ "exclude"]; 
        
        var _include_mask = 0x00;
        if (_include[0] == noone) {
            _include_mask = 0x00;
        }
        else if (_include[0] == all) {
            _include_mask = 0x7FFFFFFFFFFFFFFF;
        } else {
            var i = -1; var n = array_length(_include); repeat( n ) { i++;
                _include_mask += 0x01<<(_include[i])
            }
        }
        
        var _exclude_mask = 0x00;
        if (_exclude[0] == noone) {
            _exclude_mask = 0x00;
        }
        else if (_exclude[0] == all) {
            _exclude_mask = 0x7FFFFFFFFFFFFFFF;
        } else {
            var i = -1; var n = array_length(_exclude); repeat( n ) { i++;
                _exclude_mask += 0x01<<(_exclude[i])
            }
        }
        
		_trigger[$ "__include_mask"] = _include_mask;
        _trigger[$ "__exclude_mask"] = _exclude_mask;
        
        var _allow = [];
        var _forbid = [];
        
        _trigger[$ "allow"] ??= noone 
        if (!is_array(_trigger[$ "allow"])) {
            _trigger[$ "allow"] = [_trigger[$ "allow"]];
        }
        _allow = _trigger[$ "allow"]; 
        
        _trigger[$ "forbid"] ??= noone 
        if (!is_array(_trigger[$ "forbid"])) {
            _trigger[$ "forbid"] = [_trigger[$ "forbid"]];
        }
        _forbid = _trigger[$ "forbid"]; 
        
        var _allow_mask = 0x00;
        if (_allow[0] == noone) {
            _allow_mask = 0x00;
        }
        else if (_allow[0] == all) {
            _allow_mask = 0x7FFFFFFFFFFFFFFF;
        } else {
            var i = -1; var n = array_length(_allow); repeat( n ) { i++;
                _allow_mask += 0x01<<(_allow[i])
            }
        }
        
        var _forbid_mask = 0x00;
        if (_forbid[0] == noone) {
            _forbid_mask = 0x00;
        }
        else if (_forbid[0] == all) {
            _forbid_mask = 0x7FFFFFFFFFFFFFFF;
        } else {
            var i = -1; var n = array_length(_forbid); repeat( n ) { i++;
                _forbid_mask += 0x01<<(_forbid[i])
            }
        }

        _trigger[$ "__allow_mask"]   = _allow_mask;
        _trigger[$ "__forbid_mask"]  = _forbid_mask;
        _trigger[$ "trigger"] = method( __owner, _trigger[$ "trigger"]);
    }
    
    /// @ignore
    /// @param  {Real} trigger id
    static trigger_build = function(_id) {
        if (FASTSM_ENABLE_SAFETY) {
            if (__triggers[_id] == undefined) {
                __fastsm_warn(
                    "Trigger with id\"",
                     string(_id), 
                    "\" has not been defined yet and cannot be built. Skipping."
                )
                return;
            }
            __fastsm_log(
                "BUILDING: Trigger \"",
                __triggers[_id][$ "name"] ?? "id: " + string(_id) + " <unknown name, please provide a trigger name>",
                "\""
            )
        }
        
        __trigger_build( _id );
    }
    
    /// @param  {Real}      trigger id
    /// @param  {Struct}    trigger struct {name, include, forbid, trigger: function(source) }
    static trigger_add = function(_id, _trigger) {
        if (FASTSM_ENABLE_SAFETY) {
            if (!is_struct(_trigger)) {
                __fastsm_error(
                    "Expected trigger struct, got \"",
                    typeof(_trigger),
                    "\" instead."
                )
            }
            if (__triggers[_id] != undefined) {
                __fastsm_warn(
                    "Trigger \"",
                    _trigger[$ "name"] ?? "id: " + string(_id) + " <unknown name, please provide a trigger name>", 
                    "\" has been defined already. The previous definition has been replaced."
                )
            }
            if (_trigger[$ "trigger"] == undefined || !__valid_method(_trigger[$ "trigger"])) {
                __fastsm_error(
                    "Expected trigger function, got \"",
                    typeof(_trigger[$ "trigger"]),
                    "\" instead."
                )
            }
        }
        
        __triggers[_id] = _trigger;
    }
    
    /// @ignore
    /// @param {Int} trigger id
    /// @returns {None} none
    static __trigger_process = function(_id) {
        var _trigger	= __triggers[_id];
        var _result     =  undefined;
        
        if (__state_active == 0) {
            return;
        }
        if ((1<<__state_active) & _trigger[$ "__allow_mask"]) {
            _result = _trigger[$ "trigger"](__state_active, __states[__state_active] );
        } else {
            if ((1<<__state_active) & _trigger[$ "__forbid_mask"] || 
                _trigger[$ "__exclude_mask"] & __states[__state_active][$ "__mask"]) {
                return;
            }
            if (_trigger[$ "__include_mask"] & __states[__state_active][$ "__mask"]) {
                _result = _trigger[$ "trigger"](__state_active, __states[__state_active] );
            }
        }
        if (!_result) {
            return;
        }
        fsm_change( _result );
    }
    
    /// @param  {Real}  trigger id
    static trigger_process = function(_id) {
        if (FASTSM_ENABLE_SAFETY) {
            if (__triggers[_id] == undefined) {
                __fastsm_error(
                    "Trigger with id\"",
                     string(_id), 
                    "\" has not been defined yet and cannot be triggered."
                )
            }
            if (__triggers[_id][$ "__include_mask"] == undefined ||
				__triggers[_id][$ "__exclude_mask"] == undefined ||
                __triggers[_id][$ "__allow_mask"]	== undefined ||
                __triggers[_id][$ "__forbid_mask"]	== undefined) {
                __fastsm_error(
                    "Trigger \"",
                    __triggers[_id][$ "name"] ?? "id: " + string(_id) + " <unknown name, please provide a trigger name>", 
                    "\" has not been built yet and cannot be triggered."
                )
            }
            if ((__triggers[_id][$ "__include_mask"]	== 0x00 && 
                 __triggers[_id][$ "__allow_mask"]		== 0x00) ||
                 __triggers[_id][$ "__forbid_mask"]		== 0x7FFFFFFFFFFFFFFF || 
				 __triggers[_id][$ "__exclude_mask"]	== 0x7FFFFFFFFFFFFFFF) {
                __fastsm_warn(
                    "Trigger \"",
                    __triggers[_id][$ "name"] ?? "id: " + string(_id) + " <unknown name, please provide a trigger name>", 
                    "\" is invalid and will never be triggered."
                )
            }
        }
        
        __trigger_process(_id);
    }
    
    /// @param  {String}    event   name
    /// @param  {Function}  default event callback
    /// @returns {None} none
    static event_add_default = function(_event, _func = function() {}) {
        if (FASTSM_ENABLE_SAFETY) {
            if (!is_string(_event)) {
                __fastsm_error(
                    "Expected event identifier (typeof string), got \"",
                    typeof(_event),
                    "\" instead."
                )
            }
            if (!__valid_method(_func)) {
                __fastsm_error(
                    "Expected event default function, got \"",
                    typeof(_func),
                    "\" instead."
                )
            }
        }
        
        __default_events[$ _event] = _func;
    }
    
    /// @ignore
    /// @param  {Real}  state id
    static __fsm_change = function(_id) {
        var _next_state =       __states[_id];
        var _current_state =    __states[__state_active];
        // Execute leave event.
        _current_state[$ "leave"](_current_state, _next_state);
        
        __time = get_timer();
        __state_previous =  __state_active;
        __state_active =    _id;
        
        var _previous_state =   _current_state;
        var _current_state =    __states[__state_active];
        // Execute enter event.
        _current_state[$ "enter"](_current_state, _previous_state);
        // Can change
        var _current_state = __states[__state_active];
        
        var i = 0; repeat(array_length(__default_events_keys) ) {
            var _key =      __default_events_keys[i++];
            self[$ _key] =  _current_state[$ _key];
        }
    }
    
    /// @param  {Real}  state id
    static fsm_change = function(_id) {
        if (FASTSM_ENABLE_SAFETY) {
            if (_id == 0) {
                __fastsm_warn(
                    "Trying to change to internal state \n",
                    "This is not recommended."
                )
            }
            if (_id < 0 || _id >= __size) {
                __fastsm_error(
                    "Index \"",
                    _id,
                    "\"is out of bounds."
                )
            }
            if (__states[_id] == undefined) {
                __fastsm_error(
                    "State \"",
                    __states[_id][$ "name"] ?? "<unknown name, please provide a state name>", 
                    "\" has not been defined yet."
                )
            }
        }
        __fsm_change(_id);
    }
    
    /// @returns {Struct} current_state
    static fsm_get_active_state = function() {
        return __states[__state_active];
    }
    
    /// @returns {Struct} previous_state
    static fsm_get_previous_state = function() {
        return __states[__state_previous];
    }
    
    /// @param  {Array<Real>}   tags    tags to match
    /// @returns {Real}
    static fsm_active_has_tag = function(_tags) {
        _tags ??= noone;
        _tags = is_array(_tags) ? _tags : [_tags];
        
        var _mask = 0x00;
        if (_tags[0] == noone) {
            _mask = 0x00;
        }
        else if (_tags[0] == all) {
            _mask = 0x7FFFFFFFFFFFFFFF;
        } else {
            var i = -1; var n = array_length(_tags); repeat( n ) { i++;
                _mask += 0x01<<(_tags[i])
            }
        }
        
        return (_mask & __states[__state_active][$ "__mask"])
    }
    
    /// @returns {Real} current active state time in microseconds
    static fsm_get_current_time = function() {
        return get_timer() - __time;
    }
    
    /// @ignore
    /// @param  {Real}  state id
    static __fsm_start = function(_id) {
        __time =            get_timer();
        __state_active =    _id;
        
        var _active = __states[__state_active];
        _active[$ "enter"](_active);
        _active = __states[__state_active];
        
        var i = -1; var n = array_length(__default_events_keys); repeat(n) { i++;
            var _key =      __default_events_keys[i];
            self[$ _key] =  __states[__state_active][$ _key];
        }
    }
    
    /// @param  {Real}  state id
    static fsm_start = function(_id) {
        if (FASTSM_ENABLE_SAFETY) {
            if (_id == 0) {
                __fastsm_warn(
                    "Trying to change to internal state \n",
                    "This is not recommended."
                )
            }
            if (_id < 0 || _id >= __size) 
                __fastsm_error(
                    "Index \"",
                    _id,
                    "\"is out of bounds."
                )
            if (__states[_id] == undefined) 
                __fastsm_error(
                    "State \"",
                    __states[_id][$ "name"] ?? "<unknown name, please provide a state name>", 
                    "\" has not been defined yet."
                )
        }
        __fsm_start(_id);
    }
    
    /// @returns {FastSM} self
    static fsm_build = function() {
        __default_events_keys = variable_struct_get_names(__default_events);
        
        //we skip state 0 since it only exists for technical reasons
        var i, n;
        i = 0;  n = __size - 1; repeat( n ) { i++;
            state_build(i);
        }
        i = -1; n = __trigger_count; repeat( n ) { i++;
            trigger_build(i);
        }
        
        return self;
    }
    
    
    static add      = state_add;
    
    static trigger  = trigger_process;
    
    static change   = fsm_change;
    static start    = fsm_start;
    static build    = fsm_build;
    static time     = fsm_get_current_time;
    static current  = fsm_get_active_state;
    static previous = fsm_get_previous_state;
}
