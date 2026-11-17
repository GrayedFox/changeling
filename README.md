# CHANGELING

Because changelogs should be easy to read, write, and parse.

> [!TIP]
> A changeling is a changelog file that fully conforms to the changeling spec.

## Design Principles

The changeling spec has been designed with the following principles in mind:

1. It is (mostly) agnostic about your product, code, licences, tools, stack, and
   processes
2. It assumes that someone reading a changelog cares about *when* said changes
   went into effect (even if your version control history disagrees)
3. It assumes that someone writing a changelog cares about *where* people might
   want to go after reading it (even if not all of your readers do)
4. It stakes no claim over your commit messages
5. It treats a changeling file as an input, not an output

The [spec can be found here][1] and the [usage guide lives here][2].

The readme waxes lyrical about how this sodding spec is came about at all. The
TLDR is "naming things is hard, but describing things shouldn't be".

For the long version, keep on reading.

## The Problem

A good commit is evergreen and timeless: it touches only what it needs to (the
WHAT) and describes it's purpose (the WHY) in a way that makes sense to a
maintainer that bothers to check in eleventy years time.

A good changelog does what a commit should not: it describes the *impact* of
said changes, at a particular *point in time*, with a *specific* audience in
mind.

A bold claim: all software projects that live long enough will inevitably claim
their first changelog victim. This happens the moment someone working on or
adjacent to said project is tasked with describing changes to stakeholders that
aren't simply "other maintainers".

In essence, the measure of a changelog is how useful it is to it's audience.

Now, that *may* have something to do with your fancy coding skills, but a lot of
the time it does not, and the poor sod left to manually turn auto-generated
technical jargon into something the business/users/vendors/partners understand
and can action will surely wonder where the last three days just went.

The issue with many [existing changelog][0] formats is that more often than not
they assume something about the team or the stack. The second a changelog needs
to know the name of a branch, reads your `package.json`, or integrates with a
project management system, it binds itself to a fact about how the team builds or
organizes that it has no business knowing.

## The Solution

The 5th design principle is a lot more loadbearing and interesting than it might
at first seem. In less abstract terms: the spec does not assume that changelings
are *one and the same* as the technical document that a maintainer or product
owner ends up sharing.

This is what decouples the audience from the asset. The spec focuses on keeping
changelings easy for a *human* to read/write, and for a *program* to parse.

I suppose the implicit assumption is that you're reading this because you've got
some skin in the game when it comes to cataloguing changes, meaning there's a
good chance that you're working on/have worked on software that's a lot more
involved than reading text and matching on a token or two.

Since the changeling spec is a subset of GFM, people that legitimately need to
parse the a changelog's contents into an AST can easily do so using a host of
existing tools.

For everyone else, check the [guide][2].

## The Fool

Why not just generate a changelog based on commit messages and timestamps?

Alright bucko, you got me: yes, a commit usually ships with timestamps.

But this is metadata set by your local system clock and thus relates primarily
to the author(s) and committer(s) machines. The reason it's metadata is because
it's incidental to how the core of most version control systems actually
function, which is via orienting objects (commits) through a property of some
sort (like a hash).

Long story short: anyone that's ever done a `rebase` will tell you not to trust
a timestamp.

Truth be told that's the much smaller-and-sovleable part of the problem anyhow.

Propietary, closed-source software maintainers cannot simply copy a commit
message verbatim into a changelog that may be read by a broader audience than
just the maintainers of that codebase. This effectively amounts to granting read
permissions of a technical asset to an unknown, unvetted audience.

There's a host of perfectly valid reasons not to base your changelog on your
commit history:

- it tightly couples the content of your commit history to your changelog
- commit history can be rewritten, and as soon as that happens there's drift
- not all changes to a codebase should be advertised
- different audiences require different details and to varying degrees

[0]: https://github.com/changesets/changesets
[1]: 
[2]: 