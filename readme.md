{Simulator} - a framework for implementing simulations

Simulator} allows users to define business processes that define
how people are supposed to do their jobs in concert with others
to accomplish the organizations goals. As anyone who has ever been
with an organization, they know that people seldom do things
"by the book". Every business process varies at every point
there is a decision to be made. This framework allows you 
capture those variants in a systematic way. It allows you
to also model the human factors that influence why a person
does one variant of a process over another. If a person
is tired or hurried, they may skip steps that cause a long
term degredation of the system but cause no immediate
harm.

Central to this simulation framework is a naive attempt to
model human behavior in a deep way so that the agents 
within the simulation act in ways that feel human. The
{Person} class encapsulates this behavior which is based
on years of social science research.

The framework is also designed to allow multi-threaded,
multi-machine simulations to run at fast speeds with
full traceability so that the user can examine what
happened in a simulation and trace the effect back to
the ultimate cause or causes.

