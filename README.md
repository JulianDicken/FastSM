# FastSM
FastSM aims to be a more lightweight alternative to the fantastic SnowState library by [Sahaun](https://github.com/sohomsahaun/SnowState/).
FastSM employs different design paradigms which make it more flexible in certain cases, while making it more restrictive in others.
Hard limits FastSM has are :
- There can never be more than 64 State Tags per FSM
- There can never be more than 64 States per FSM if you are using the allow/forbid feature of state transitions.
 
I will be documenting FastSM properly soon but for now you can find example code here :
```js
enum Tag {
    A,
    B,
    C
}
enum State {
    None, //required, any name allowed
    Foo,
    Bar,
    Baz,
    MAX //QoL
}
enum Trigger {
    A,
    MAX
}
fsm = new FastSM(State.MAX, Trigger.MAX);
fsm.event_add_default("update");

fsm.add( State.Baz, {
    name : "I should never show up in this example!",
    enter : function(this) {
       show_debug_message(this.name)
    }
});

fsm.add( State.Bar, {
    name : "I should show up in this example!",
    tags : Tag.C,
    enter : function(this) {
       show_debug_message(this.name)
    }, 
    update : function() {
         show_debug_message("update should be called!")
    }
});

fsm.add( State.Foo, {
    name : "I am the entry state!",
    tags : [Tag.A, Tag.B],
    enter : function(this) {
        show_debug_message(this.name)
    }
});

fsm.trigger_add( Trigger.A, {
    name : "Trigger A",
    include: all,
    forbid: State.Bar,
    trigger : function(_source) {
        switch _source {
            case State.Foo:
                return State.Bar;
            break;
            case State.Bar:
                return State.Baz;
            break;
            default:
                return State.None;
        }
    }
});

fsm.build().start( State.Foo );
fsm.trigger( Trigger.A );
fsm.trigger( Trigger.A );
fsm.trigger( Trigger.A );
fsm.update();
```
