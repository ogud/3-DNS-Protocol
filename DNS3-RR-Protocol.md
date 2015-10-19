% title = "Third Party DNS operator to Registrars/Registries Protocol"
% abbrev = "3-DNS-RRR" 
% category = "info"
% ipr="trust200902"
% docName = "draft-ogud-dnsoperator-to-RRR-protocol-00"
% area = "Applications" 
% workgroup = ""
% keyword = ["dnssec", "delegation maintainance", "trust anchors"]
%
% date = 2015-10-08T00:00:00Z
%
% [[author]]
% initials = "O."
% surname = "Gudmundsson"
% fullname = "Olafur Gudmundsson"
% organization = "Cloudflare, Inc."
%  [author.address] 
%  email = "olafur+ietf@cloudflare.com"
%  street = "San Francisco, CA, 94107"
%
% [[author]]
% fullname="Paul Wouters" 
% initials = "P."
% surname = "Wouters"
% organization="Red Hat"
%  [author.address]
%  email="paul@nohats.ca"
%
% [[author]]
% fullname="Matthew Pounsett" 
% initials="M."
% surname="Pounsett"
% organization="Rightside"
%   [author.address] 
%   street="Toronto, ON"
%   email="matt@conundrum.com"
%
% [[author]]
% fullname = "Jacques Latour" 
% initials = "J."
% surname = "Latour"
% organization="CIRA"
%   [author.address] 
%   street="Ottawa ,ON" 
%   email="jacques.latour@cira.ca"

.# Abstract
There are several problems that arise in the standard
Registrant/Registrar/Registry model when the operator of a zone is
neither the Registrant nor the Registrar for the delegation.  Historically
the issues have been minor, and limited to difficulty guiding the
Registrant through the initial changes to the NS records for the
delegation.  As this is usually a one time activity when the operator first
takes charge of the zone it has not been treated as a serious issue.

When the domain on the other hand uses DNSSEC it necessary for the Registrant in this
situation to make regular (sometimes annual) changes to the delegation in
order to track KSK rollover, by updating the delegation's DS record(s).
Under the current model this is prone to Registrant error and significant
delays. Even when the Registrant has outsourced the operation of DNS to a third party
the registrant still has to be in the loop to update the DS record. 

There is a need for a simple protocol that allows a third party DNS
operator to update DS and NS records for a delegation without involving
the registrant for each operation.

The protocol described in this draft is REST based, and when used through
an authenticated channel can be used to bootstrap DNSSEC.  Once DNSSEC is
established this channel can be used to trigger maintenance of delegation
records such as DS, NS, and glue records.   The protocol is kept as simple as possible. 


{mainmatter}

# Introduction
Why is this needed ? 
DNS registration systems today are designed around making
registrations easy and fast. After the domain has been registered the 
there are really three options on who maintains the DNS zone that is
loaded on the "primary" DNS servers for the domain this can be the
Registrant, Registar, or a third party. 

Unfortunatley the ease to make changes differes for each one of these
options. The Registrant needs to use the interface that the registar
provides to update NS and DS records. The Registrar on the other hand
can make changes directly into the registration system. The third
party operator on the hand needs to go through the Registrant to
update any delegation information. 

Current system does not work well, there are many examples of failures
including the inabilty to upload DS records du to non-support by
Registar interface, the registrant forgets/does-not perform action but
tools proceed with key rollover without checking that the new DS is in
place. Another common failure is the DS record is not removed when the
DNS operator changes from one that supports DNSSEC signing to one that
does not. 

The failures result either inabilty to use DNSSEC or in validation
failures that case the domain to become invalid and all users that are
behind validating resolvers will not be able to to access the domain. 


# Notational Conventions

    
## Definitions
For the purposes of this draft, a third-party DNS operator is any
DNS operator responsible for a zone where the operator is neither
the Registrant nor the Registrar of record for the delegation.

When we say Registrar that can in many cases be applied to a Reseller
i.e. an entity that sells delegations but registrations are processed
through the Registrar. 

## RFC2119 Keywords
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL",
"SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and
"OPTIONAL" in this document are to be interpreted as described
in [@RFC2119].

# What is the goal ? 
The primary goal is to use the DNS protocol to provide information from
child zone to the parent zone, this is a way to maintain the
delegation information. The precondition for this to be practical is
that the domain is DNSSEC signed. 

IN the general case there should be a way to find the right
Registrar/Registry entity to talk to but that does not exist. Whois[]
is the natural protocol to carry such information but that protcol is
unreliable and hard to parse. Its proposed successor RDAP [@RFC7480]
has yet be deployed on any TLD. 

The preferred communication mechanism is to use is to use a REST [@RFC6690]
call to start processing of the requested delegation information. 

## Why DNSSEC ? 
DNSSEC [@!RFC4035] provides data authentication for DNS answers,
having DNSSEC enabled makes it possible to trust the answers. The
biggest stumbling block is deploying DNSSEC is the intial
configuration of the DNSSEC domain trust anchor in the parent, DS
record. 

## How does Domain signal to parent it wants DNSSEC Trust Anchor ? 
The child needs first to sign the domain, then the child can "upload"
the DS record. The "normal" way to upload is to go through
registration interface, but that fails frequently. The DNS operator
may not have access to the interface thus the registrant needs to
relay the information. For large operations this does not scale, as
evident in lack of Trust Anchors for signed deploymentns that are
operated by third parties. 

The child can signal its desire to have DNSSEC validation enabled by
publishing one of the special DNS records CDS and/or
CDNSKEY[@!RFC7344]. Once the "parent" "sees" these records it SHOULD
start acceptance processing. This document will cover below how to
make the CDS records visilbe to the right parental agent. 

We argued that the publication of CDS/CDNSKEY record is sufficent for
the parent to start acceptance processing, the main point is to
provide authentication thus if the child is in "good" state and the DS
upload should be simple to accept and publish. If at any time the
parent has abilty to remove the DS if it discovers that the DS was
upploaded in error.  

## What checks are needed by parent ?
The parent uppon receiving a signal that it check the child for desire
for DS record publication. The basic tests include, 
    #. All the nameservers for the zone agree on zone contents 
    #. The zone is signed 
    #. The zone has a CDS signed by the KSK referenced i the CDS 

Parents can have additional tests, defined delays, and even ask the
DNS operator to prove they can add data to the zone, or provide a code
that is tied to the affected zone. 

# OP-3-DNS-RR Protocol

## Command 
The basic call is 
      <SERVER>Update/<domain>/

The following options to the commands are specified

   "auth="   an authenticaion token

   "debug="  request a debug session
  

## Answers
The basic answer is a jason blob the these are some possible blocks in
the response: 

   "refer:"  will contain an URI; this is an referal to an URI that is better able to do execute the command

   "refused:"  This command can not be executed, and the reason is inside the block

   "debug:"  list of debug messages normally empty unless debug flag is 
present, this section should be ignored in normal processing

   "error:"  if there was one look inside debug for more details

   "domain:" what domain this is an answer for this section MUST be included in all answers

   "rr:"  the new list of rrs "can be empty" 

   "id:"  An identifier for the transaction 

If ``refer'' block is present in answer then the client is instructed to 
connect to that URI and retry the command there. Client SHOULD
always honor the refer command over all other answers it gets in
the answer.

# Authorization

The authorization can be either based on Token (like auth code) or buy
challenge i.e. inserting a blob into the zone.  It is up to registrars
to register the referral URI with registries, or block the access to
updating DS and NS.  

OAUTH??? would work how ??? 

# Security considerations

TBD This will hopefully get more zones to become validated thus
overall the security gain outweights the possible drawbacks. 


# IANA Actions
URI ??? TBD


# Internationalization Considerations
This protcol is designed for machine to machine communications 

{backmatter}

# Document History
First rough version


