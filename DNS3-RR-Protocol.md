% title = "Third Party DNS operator to Registrars/Registries Protocol"
% abbrev = "3-DNS-RRR"
% category = "info"
% ipr="trust200902"
% docName = "draft-latour-dnsoperator-to-rrr-protocol-03.txt"
% area = "Applications"
% workgroup = ""
% keyword = ["dnssec", "delegation maintainance", "trust anchors"]
%
% date = 2016-03-21T00:00:00Z
%
% [[author]]
% fullname = "Jacques Latour"
% initials = "J."
% surname = "Latour"
% organization="CIRA"
%   [author.address]
%   street="Ottawa, ON"
%   email="jacques.latour@cira.ca"
%
% [[author]]
% initials = "O."
% surname = "Gudmundsson"
% fullname = "Olafur Gudmundsson"
% organization = "Cloudflare, Inc."
%  [author.address]
%  email = "olafur+ietf@cloudflare.com"
%  street = "San Francisco, CA"
%
% [[author]]
% fullname="Paul Wouters"
% initials = "P."
% surname = "Wouters"
% organization="Red Hat"
%  [author.address]
%  street="Toronto, ON"
%  email="paul@nohats.ca"
%
% [[author]]
% fullname="Matthew Pounsett"
% initials="M."
% surname="Pounsett"
% organization="Rightside Group, Ltd."
%  [author.address]
%  street="Toronto, ON"
%  email="matt@conundrum.com"
%

.# Abstract
There are several problems that arise in the standard
Registrant/Registrar/Registry model when the operator of a zone is neither the
Registrant nor the Registrar for the delegation. Historically the issues have
been minor, and limited to difficulty guiding the Registrant through the
initial changes to the NS records for the delegation. As this is usually a
one time activity when the operator first takes charge of the zone it has not
been treated as a serious issue.

On the other hand, when the domain is signed with DNSSEC it is necessary for
the DS records in the parent delegation to be changed regularly in order to
track KSK rollover. In the current model, this is subject to delays, as the
DNS operator must get the attention of the registrant, and is error prone, as
the registrant must successfully copy and paste DS data or DNSKEY data, which
is difficult to visually compare.

There is a need for a simple protocol that allows a third party DNS operator
to update DS and NS records for a delegation, in a trusted manner, without
involving the registrant in each operation.

The protocol described in this draft is REST based, and when used through an
authenticated channel can be used to establish the DNSSEC Initial Trust (to
turn on DNSSEC or bootstrap DNSSEC). Once DNSSEC trust is established this
channel can be used to trigger maintenance of delegation records such as DS,
NS, and glue records. The protocol is kept as simple as possible.

{mainmatter}

# Introduction

DNS registration systems are designed around making registrations easy and
fast. When it comes to setting up the master (or primary) DNS service, the
level of ease varies greatly depending on whether the DNS operator is the
registrar, registrant, or a third party.

When the registrar is the DNS operator, it is able to directly and
automatically make changes at the registray as necessary. If the registrant
is the DNS operator, they can make whatever changes they need using whatever
interface the registrar provides. A third party DNS operator, on the other
hand, must go through the registrant (who may or may not be technically
capable) in order to have changes submitted through the registrar to the
registry.

There are many examples of common failure modes with a third-party DNS
operator:
   - submission of incorrect data to the registrar due to copy and paste
     errors, or unintentionally omitting important data
   - registrants failing to submit data to the registrar in a timely manner
   - failure to remove DS records when moving from a DNS operator that
     supports DNSSEC to one that does not

These sorts of human errors can result in partial or complete failure of a
zone for anyone using a DNSSEC validating resolver. The protocol described by
this draft is intended to simplify the process of updating delegation
information, for both the registrant and third party DNS operators, by
enabling automation and eliminating obvious and common sources of human
error.

# Notional Conventions

## Definitions

For the purposes of this draft, a third-party DNS Operator is any DNS Operator
responsible for a zone where the operator is neither the Registrant nor the
Registrar of record for the delegation.

Uses of the word 'Registrar' in this document may also be applied to
resellers: an entity that sells delegations through a registrar with whom the
entity has a reseller agreement.

## RFC2119 Keywords

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [@RFC2119].

# What is the goal?
The primary goal is to use the DNS protocol to provide information from child
zone to the parent zone, to maintain the delegation information. The
precondition for this to be practical is that the domain is DNSSEC signed.

In the general case there should be a way to find the right Registrar/Registry
entity to talk to but that does not exist. Whois[] is the natural protocol to
carry such information but that protocol is unreliable and hard to parse. Its
proposed successor RDAP [@RFC7480] has yet be deployed on most TLD's.

The preferred communication mechanism is to use is to use a REST [@RFC6690]
call to start processing of the requested delegation information.

## Why DNSSEC?
DNSSEC [@!RFC4035] provides data authentication for DNS answers, having DNSSEC
enabled makes it possible to trust the answers. The biggest stumbling block is
deploying DNSSEC is the initial configuration of the DNSSEC domain trust
anchor in the parent, DS record.

## How does a child signal its parent it wants DNSSEC Trust Anchor?
The child needs first to sign the domain, then the child can "upload" the DS
record to its parent. The "normal" way to upload is to go through registration
interface, but that fails frequently. The DNS Operator may not have access to
the interface thus the registrant needs to relay the information. For large
operations this does not scale, as evident in lack of Trust Anchors for signed
deployments that are operated by third parties.

The child can signal its desire to have DNSSEC validation enabled by
publishing one of the special DNS records CDS and/or CDNSKEY[@!RFC7344] and
its proposed extension [@!I-D.ietf-dnsop-maintain-ds#00].

Once the "parent" "sees" these records it SHOULD start acceptance processing.
This document will cover below how to make the CDS records visible to the
right parental agent.

We and [@I-D.ogud-dnsop-maintain-ds#00] argue that the publication of
CDS/CDNSKEY record is sufficient for the parent to start the acceptance
processing. The main point is to provide authentication thus if the child is
in "good" state then the DS upload should be simple to accept and publish. If
there is a problem the parent has ability to not add the DS.

## What checks are needed by parent?
The parent upon receiving a signal that it check the child for desire for DS
record publication. The basic tests include,
    1. The zone is signed
    2. The zone has a CDS signed by a KSK referenced in the current DS,
       referring to a at least one key in the current DNSKEY RRset
    3. All the name-servers for the zone agree on the CDS RRset contents

Parents can have additional tests, defined delays, queries over TCP, and even
ask the DNS Operator to prove they can add data to the zone, or provide a code
that is tied to the affected zone. The protocol is partially-synchronous,
i.e. the server can elect to hold connection open until the operation has
concluded or it can return that it received the request. It is up to the child
to monitor the parent for completion of the operation and issue possible
follow-up calls.

# OP-3-DNS-RR RESTful API

The specification of this API is minimalist, but a realistic one. Question:
How to respond if the party contacted is not ALLOWED to make the requested
change?

## Authentication
The API does not impose any unique server authentication requirements. The
server authentication provided by TLS fully addresses the needs. In general,
for the API SHOULD be provided over TLS-protected transport (e.g., HTTPS) or
VPN.

## Authorization
Authorization is out of scope of this document. The CDS records present in the
zone file are indications of intention to sign/unsign/update the DS records of
the domain in the parent zone. This means the proceeding of the action is not
determined by who issued the request. Therefore, authorization is out of the
scope. Registries and registrars who plan to provide this service can,
however, implement their own policy such as IP white listing, API key, etc.

## Base URL Locator

The base URL for registries or registrars who want to provide this service to
DNS Operators can be made auto-discoverable as an RDAP extension.

## CDS resource
Path: /domains/{domain}/cds
{domain}: is the domain name to be operated on

### Initial Trust Establishment (Enable DNSSEC validation)
#### Request
Syntax: POST /domains/{domain}/cds

A DS record based on the CDS record in the child zone file will be inserted
into the registry and the parent zone file upon the successful completion of
such request. If there are multiple CDS records in the CDS RRset, multiple DS
records will be added.

Either the CDS/CDNSKEY or the DNSKEY can be used to create the DS record.
Note: entity expecting CDNSKEY is still expected accept the /cds command.

#### Response
   - HTTP Status code 201 indicates a success.
   - HTTP Status code 400 indicates a failure due to validation.
   - HTTP Status code 403 indicates a failure due to an invalid challenge token.
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.


### Removing a DS (turn off DNSSEC)
#### Request
    Syntax: DELETE /domains/{domain}/cds

#### Response
   - HTTP Status code 200 indicates a success.
   - HTTP Status code 400 indicates a failure due to validation.
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.

### DS Maintenance (Key roll over)
#### Request
    Syntax: PUT /domains/{domain}/cds

#### Response
   - HTTP Status code 200 indicates a success.
   - HTTP Status code 400 indicates a failure due to validation.
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.

## Tokens resource
   Path: /domains/{domain}/tokens
   {domain}: is the domain name to be operated on

### Setup Initial Trust Establishment with Challenge
#### Request
    Syntax: POST /domains/{domain}/tokens

A random token to be included as a _delegate TXT record prior establishing the
DNSSEC initial trust.

#### Response
   - HTTP Status code 200 indicates a success.  Token included in the body of the response,
     as a valid TXT record
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.


## Customized Error Messages
Service providers can provide a customized error message in the response body
in addition to the HTTP status code defined in the previous section.

This can include an Identifiying number/string that can be used to track the
requests.

#Using the definitions
This section at the moment contains comments from early implementers

## How to react to 403 on POST cds
The basic reaction to a 403 on POST /domains/{domain}/cds is to issue POST /domains/{domain}/tokens
command to fetch the challenge to insert into the zone.

# Security considerations

TBD This will hopefully get more zones to become validated thus overall the
security gain out weights the possible drawbacks.

risk of takeover ?
risk of validation errors < declines
transfer issues

# IANA Actions
URI ??? TBD


# Internationalization Considerations
This protocol is designed for machine to machine communications

{backmatter}

# Document History

## Version 03
Clarified based on comments and questions from early implementors

## Version 02
Reflected comments on mailing lists

## Version 01
This version adds a full REST definition this is based on suggestions from
Jakob Schlyter.


## Version 00
First rough version


