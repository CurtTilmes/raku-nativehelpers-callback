use NativeCall;

class NativeHelpers::Callback
{
    my %allobjects;
    my $lock = Lock.new;

    method id($thing --> int64) { nativecast(int64, $thing) }

    method lookup(int64 $id)
    {
        $lock.protect: { %allobjects{$id} }
    }

    method store($object, $thing)
    {
        $lock.protect: { %allobjects{$.id($thing)} = $object }
    }

    method remove($thing)
    {
        $lock.protect: { %allobjects{$.id($thing)}:delete }
    }
}

sub cb() is export(:cb) { NativeHelpers::Callback }

=begin pod

=head1 NAME

NativeHelpers::Callback - Helper for looking up Raku objects from C callbacks

=head1 SYNOPSIS

  use NativeHelpers::Callback;

  class thing is repr('CPointer') {}

  sub make_a_thing(--> thing) is native {}
  sub setcallback(&callback (int64 --> int32), int64) is native {}

  class RakuObject
  {
      has thing $.thing;
      has int32 $.number;
  }

  sub my-callback(int64 $user-data --> int32)
  {
      NativeHelpers::Callback.lookup($user-data).number
  }

  my $object = RakuObject.new(thing => make_a_thing, number => 12);

  NativeHelpers::Callback.store($object, $object.thing);

  setcallback(&my-callback, NativeHelpers::Callback.id($object.thing));

  my $ret = callit();

  # You can also use option ":cb" to get a shorthand "cb":

  cb.store($object, $object.thing);
  cb.lookup($id);
  setcallback(&my-callback, cb.id($object.thing));
  cb.remove($object.thing);

=head1 DESCRIPTION

C libraries often have callback routines allowing you to pass in an
extra C<void *> parameter of user data from which you are supposed to
link into whatever functionality you need from within the callback.

When using Raku routines as callbacks, naturally you want to pass in
your Raku object.  This is complicated by the fact that the Garbage
Collector can potentially move Raku objects around so they may not be
found where you initially put them.

This simple helper object associates a perl object with some object
that can be cast to a C<int64> type so you can easily register the
object (C<store>/C<remove>), and C<lookup> from within a callback
routine, associated with an C<id> of that thing.

Note this is 64-bit architecture specific, and assumes C<void *>
pointers are interchangeable with C<int64>.

Wherever you see a C<void *> in a library.h file, just use C<int64>
for the Raku NativeCall subroutine that calls it.

For example:

    typedef int (*callback)(void *);
    void setcallback(callback cb, void *user_data);

goes to:

    sub setcallback(&callback (int64 --> int32), int64)
         is native('./callback') {}

=head1 COPYRIGHT and LICENSE

Copyright 2019 Curt Tilmes

This module is free software; you can redistribute it and/or modify it
under the Artistic License 2.0.

=end pod
