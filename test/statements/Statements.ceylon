void statements() {
    
    class X() {
        shared String hello = "hello";
        shared void doIt() {}
    }
    void y() {}
    X x { return x; }
    
    X();
    y();
    X().doIt();
    { X() }[].doIt();
    X? xn = null;
    xn?.doIt();
    
    @error x;
    @error X().hello;
    @error x.hello;
    
    @error "Hello" + "World";
    @error "Hello"[0];
    @error { "Hello", "World" };
    @error { X() }[].hello;
    @error xn?.hello;
    
    @error true;
    
}