package com.redhat.ceylon.compiler.typechecker.model;

public abstract class MethodOrValue extends TypedDeclaration {

    @Override
    public DeclarationKind getDeclarationKind() {
        return DeclarationKind.MEMBER;
    }

}
