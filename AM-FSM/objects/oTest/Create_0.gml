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

fsm.transition_add( Trigger.A, {
    name : "Trigger A",
    include: all,
    forbid: State.Bar,
    transition : function(_source) {
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
