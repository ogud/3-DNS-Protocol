% title = "Third Party DNS operator to Registrars/Registries Protocol"
% abbrev = "3-DNS-RRR" 
% category = "std"
% ipr="trust200902"
% docName = "draft-ietf-regext-dnsoperator-to-rrr-protocol-01.txt"
% workgroup = "regext"
% area = "Applications" 
% keyword = ["dnssec", "delegation maintenance", "trust anchors"]
%
% date = 2017-01-04T00:00:00Z
%
% [[author]]
% fullname = "Jacques Latour"
% initials = "J."
% surname = "Latour"
% organization="CIRA"
%   [author.address]
%   email="jacques.latour@cira.ca"
%   [author.address.postal]
%   city="Ottawa"
%   region="ON"
%
% [[author]]
% initials = "O."
% surname = "Gudmundsson"
% fullname = "Olafur Gudmundsson"
% organization = "Cloudflare, Inc."
%  [author.address]
%  email = "olafur+ietf@cloudflare.com"
%  [author.address.postal]
%  city = "San Francisco"
%  region = "CA"
%
% [[author]]
% fullname="Paul Wouters"
% initials = "P."
% surname = "Wouters"
% organization="Red Hat"
%  [author.address]
%  email="paul@nohats.ca"
%  [author.address.postal]
%  city="Toronto"
%  region="ON"
%
% [[author]]
% fullname="Matthew Pounsett"
% initials="M."
% surname="Pounsett"
% organization="Rightside Group, Ltd."
%  [author.address]
%  email="matt@conundrum.com"
%  [author.address.postal]
%  city="Toronto"
%  region="ON"
%

.# Abstract

There are several problems that arise in the standard
Registrant/Registrar/Registry model when the operator of a zone is neither the
Registrant nor the Registrar for the delegation. Historically the issues have
been minor, and limited to difficulty guiding the Registrant through the
initial changes to the NS records for the delegation. As this is usually a
one time activity when the operator first takes charge of the zone it has not
been treated as a serious issue.

When the domain uses DNSSEC it necessary to make regular (sometimes annual)
changes to the delegation, updating DS record(s) in order to track KSK
rollover.  Under the current model this is prone to delays and errors, as the
Registrant must participate in updates to DS records.

This document describes a simple protocol that allows a third party DNS
operator to update DS and NS records for a delegation, in a trusted manner,
without involving the Registrant for each operation. This same protocol can be
used by Registrants.

{mainmatter}

# Introduction

After a domain has been registered, one of three parties will maintain the DNS
zone loaded on the "primary" DNS servers: the Registrant, the Registrar, or a
third party DNS operator.  DNS registration systems were originally designed
around making registrations easy and fast, however after registration the
complexity of making changes to the delegation differs for each of these
parties.  The Registrar can make changes directly in the Registry systems
through some API (typically EPP [@RFC5730]).  The Registrant is typically
limited to using a web interface supplied by the Registrar.  A third party DNS
Operator must to go through the Registrant to update any delegation
information.

In this last case, the operator must contact and engage the Registrant in
updating NS and DS records for the delegation.  New information must be
communicated to the Registrant, who must submit that information to the
Registrar.  Typically this involves cutting and pasting between email and a
web interface, which is error prone.  Furthermore, involving Registrants in
this way does not scale for even moderately sized DNS operators. Tracking
thousands (or millions) of changes sent to customers, and following up if
those changes are not submitted to the Registrar, or are submitted with
errors, is itself expensive and error prone.

The current system does not work well, as there are many types of failures
that have been reported at all levels in the registration model.  The failures
result in either the inability to use DNSSEC or in validation failures that
cause the domain to become unavailable to users behind validating resolvers.

The goal of this document is to create a protocol for establishing a secure
chain of trust that involves parties not in the traditional
Registrant/Registrar/Registry (RRR) model, and to reduce the friction in
maintaining DNSSEC secured delegations in these cases.  It describes a
REST-based [@!RFC6690] protocol which can be used to establish DNSSEC initial
trust (to enable or bootstrap DNSSEC), and to trigger maintenance of
delegation records such as DS, NS, and glue records.

# Notional Conventions

## Definitions

For the purposes of this draft, a third-party DNS Operator is any DNS Operator
responsible for a zone, where the operator is neither the Registrant nor the
Registrar of record for the delegation.

Uses of "child" and "parent" refer to the relationship between DNS zone
operators.  In this document, unless otherwise noted, the child is the
third-party DNS operator and the parent is the Registry.

Uses of the words "Registrar" or "Registration Entity" in this document may
also be applied to Resellers or to Registries that engage in registration
activities directly with Registrants.  Unless otherwise noted, they are used
to refer to the entity which has a direct business relationship with the
Registrant.  

## RFC2119 Keywords

The key words "MUST", "MUST NOT", "REQUIRED", "SHALL", "SHALL NOT", "SHOULD",
"SHOULD NOT", "RECOMMENDED", "MAY", and "OPTIONAL" in this document are to be
interpreted as described in [@RFC2119].

# Process Overview

## Identifying the Registrar

As of publication of this document, there has never been a standardized or
widely deployed method for easily and scalably identifying the Registar for a
particular registration.

At this time, WHOIS [@RFC3912] is the only widely deployed protocol to carry
such information, but WHOIS responses are unstructured text, and each
implementor can lay out its text responses differently.  In addition,
Registries may include referrals in this unstructured text to the WHOIS
interfaces of their Registrars, and those Registrar WHOIS interface in turn
have their own layouts.  This presents a text parsing problem which is
infeasible to solve.

RDAP, the successor to WHOIS, described in [@RFC7480], solves the problems of
unstructured responses, and a consistently implemented referral system,
however at this time RDAP has yet to be deployed at most Registries. 

With no current mechanism in place to scalably discover the Registar for a
particular registration, the problem of automatic discovery of the base URL 
of the API is considered out of scope of this document.  The authors recommend
standardization of an RDAP extension to obtain this information from the
Registry.

## Establishing a Chain of Trust

After signing the zone, the child operator needs to upload the DS record(s) to
the parent.  The child can signal its desire to have DNSSEC validation enabled
by publishing one of the special DNS records CDS and/or CDNSKEY as defined in
[@!RFC7344] and [@!I-D.ietf-dnsop-maintain-ds].

A> [RFC Editor: The above I-D reference should be replaced with the correct
RFC number upon publication.]

In the case of an insecure delegation, the Registrar will normally not be
scanning the child zone for CDS/CDNSKEY records.  The child operator can use
this protocol to notify the Registrar to begin such a scan.

Once the Registrar sees these records it SHOULD start acceptance processing.

## Maintaining the Chain of Trust

One the secure chain of trust is established, the Registrar SHOULD regularly
check the child zone for CDS/CDNSKEY record changes.  The Registrar SHOULD
also accept signals via this protocol to immediately check the child zone for
CDS/CDNSKEY records.

Server implementations of this protocol MAY include rate limiting to protect
their systems and the systems of child operators from abuse.

Each parent operator and Registrar is responsible for developing,
implementing, and communicating their DNSSEC maintenance policies.

## Other Delegation Maintenance

A> [ Not yet defined ]

## Acceptance Processing

The Registrar, upon receiving a signal or detecting through polling that the
child desires to have its delegation updated, SHOULD run a series of tests to
ensure that updating the parent zone will not create or exacerbate any
problems with the child zone. The basic tests SHOULD include:

  - checking that the child zone is is properly signed as per the Registrar
    and parent DNSSEC policy
  - if updating the DS record, checking that the child CDS RRset references a
    KSK which is present in the child DNSKEY RRset and signs the CDS RRset
  - ensuring all name servers in the apex NS RRset of the child zone agree on
    the apex NS RRset and CDS RRset contents

The Registrar SHOULD NOT make any changes to the DS RRset if the child name
servers do not agree on the CDS/CDNSKEY content.

A> [NOTE: Do we need a new section in the DPS for the CDS management policy
A> [@RFC6841]?]
	
Registrars MAY require compliance with additional tests, particularly in the
case of establishing a new chain of trust, such as:

  - checking that all child name servers to respond with a consistent
    CDS/CDNSKEY RRset for a number of queries over an extended period of time
    to minimise the possibility of an attacker spoofing responses
  - requiring the child name servers to respond with identical CDS/CDNSKEY
    RRsets over TCP
  - ensuring zone delegation best practices (for examples, see
    [@I-D.wallstrom-dnsop-dns-delegation-requirements]
  - requiring the child operator to prove they can add data to the zone (for
    example, by publishing a particular token)
  
# API Definition

This protocol is partially synchronous, meaning the server can elect to hold
connections open until operations have completed, or it can return a status
code indicating that it has received a request, and close the connection.  It
is up to the child to monitor the parent for completion of the operation, and
issue possible follow-up calls to the Registrar.

Clients may be denied access to change the DS records for domains that are
Registry Locked (HTTP Status code 401).  Registry Lock is a mechanism
provided by certain Registries or Registrars that prevents domain hijacking by
ensuring no attributes of the domain are changeable, and no transfer or
deletion transactions can be processed against the domain name without manual
intervention.

## Authentication

The API does not impose any unique server authentication requirements. The
server authentication provided by TLS fully addresses the needs of this
protocol. The API MUST be provided over TLS-protected transport (e.g., HTTPS)
or VPN.

Client authentication is considered out of scope of this document.  The
publication of CDS/CDNSKEY records in the child zone is an indication that the
child operator intends to perform DS-record-updating activities (add/delete)
in the parent zone.  Since this protocol is simply a signal to the Registrar
that they should examine the child zone for such intentions, additional
authentication of the client making the request is considered unnecessary.

Registrars MAY implement their own policy to protect acces to the API, such as
with IP whitelisting, client TLS certificates, etc..  Registrars SHOULD take
steps to ensure that a lack of additional authentication does not open up a
denial of service mechanism against the systems of the Registrar, the
Registry, or the child operator.

## RESTful Resources

In the following text, "{domain}" is the child zone to be operated on.

### CDS resource

Path: /domains/{domain}/cds

#### Establishing Initial Trust (Enabling DNSSEC)

##### Request

Syntax: POST /domains/{domain}/cds

Request that an initial set of DS records based on the CDS record in the child
zone be inserted into the Registry and the parent zone upon the successful
completion of the request. If there are multiple CDS records in the CDS RRset,
multiple DS records will be added.

##### Response
   - HTTP Status code 201 indicates a success.
   - HTTP Status code 400 indicates a failure due to validation.
   - HTTP Status code 401 indicates an unauthorized resource access.
   - HTTP Status code 403 indicates a failure due to an invalid challenge token.
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 409 indicates the delegation already has a DS RRset.
   - HTTP Status code 429 indicates the client has been rate-limited.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.

This request is for setting up initial trust in the delegation.  The Registrar
SHOULD return a status code 409 if it already has a DS RRset for the child
zone.

Upon receipt of a 403 response the child operator SHOULD issue a POST for the
"token" resource to fetch a challenge token to insert into the zone.

#### Removing DS Records
##### Request

Syntax: DELETE /domains/{domain}/cds

Request that the Registrar check for a null CDS or CDNSKEY record in the child
zone, indicating a request that the entire DS RRset be removed.  This will
make the delegation insecure.

##### Response
   - HTTP Status code 200 indicates a success.
   - HTTP Status code 400 indicates a failure due to validation.
   - HTTP Status code 401 indicates an unauthorized resource access.
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 412 indicates the parent does not have a DS RRset
   - HTTP Status code 429 indicates the client has been rate-limited.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.

#### Modifying DS Records
##### Request

Syntax: PUT /domains/{domain}/cds

Request that the Registrar modify the DS RRset based on the CDS/CDNSKEY
available in the child zone.  As a result of this request the Registrar SHOULD
add or delete DS records as indicated by the CDS/CDNSKEY RRset, but MUST NOT
delete the entire DS RRset.

##### Response
   - HTTP Status code 200 indicates a success.
   - HTTP Status code 400 indicates a failure due to validation.
   - HTTP Status code 401 indicates an unauthorized resource access.
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 412 indicates the parent does not have a DS RRset
   - HTTP Status code 429 indicates the client has been rate-limited.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.

### Token resource

Path: /domains/{domain}/token

#### Establish Initial Trust with Challenge

##### Request

Syntax: GET /domains/{domain}/token

The DNSSEC policy of the Registrar may require proof that the DNS Operator is
in control of the domain.  The token API call returns a random token to be
included as a TXT record for the _delegate.@ domain name (where @ is the apex
of the child zone) prior establishing the DNSSEC initial trust.  This is an
additional trust control mechanism to establish the initial chain of trust.

Once the child operator has received a token, it SHOULD be inserted in the
zone and the operator SHOULD proceed with a POST of the cds resource.

The Registrar MAY expire the token after a reasonable period.  The Registrar
SHOULD document an explanation of whether and when tokens are expired in their
DNSSEC policy.

Note that the _delegate TXT record is publicly available and not a secret
token.

##### Response
   - HTTP Status code 200 indicates a success.  A token is included in the
	 body of the response, as a valid TXT record
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.

## Customized Error Messages

Registrars MAY provide a customized error message in the response body in
addition to the HTTP status code defined in the previous section.  This
response MAY include an identifying number/string that can be used to track
the request.

# Security considerations

When zones are properly provisioned, and delegations follow standards and best
practices (e.g. [@I-D.wallstrom-dnsop-dns-delegation-requirements]), the
Registrar or Registry can trust the DNS information it receives from multiple
child name servers, over time, and/or over TCP to establish the initial chain
of trust.

In addition, the Registrar or Registry can require the DNS Operator to prove
they control the zone by requiring the child operator to navigate additional
hurdles, such as adding a challenge token to the zone.

This protocol should increase the adoption of DNSSEC, enabling more zones to
become validated thus overall the security gain outweighs the possible
drawbacks.

Registrants and DNS Operators always have the option to establish the chain of
trust in band via the standard Registrant/Registrar/Registry model.

# IANA Actions

This document has no actions for IANA

# Internationalization Considerations

This protocol is designed for machine to machine communications.  Clients and
servers should use punycode [@!RFC3492] when operating on internationalized
domain names.

{backmatter}

# Document History

## regext Version 03 (not yet published)
  - simplify abstract
  - move all justification text to Intro
  - added HTTP response codes for rate limiting (429), missing DS RRsets
	(412)
  - expanded on Internationalization Considerations
  - corrected informative/normative document references
  - clarify parent/Registrar references in the draft
  - general spelling/grammar/style cleanup

## regext Version 02 
  - Clarified based on comments and questions from early implementors (JL)
  - Text edits and clarifications. 

## regext Version 01 
  - Rewrote Abstract and Into (MP) 
  - Introduced code 401 when changes are not allowed 
  - Text edits and clarifications. 

## regext Version 00 
  - Working group document same as 03, just track changed to standard

## Version 03
  - Clarified based on comments and questions from early implementors

## Version 02
  - Reflected comments on mailing lists

## Version 01
  - This version adds a full REST definition this is based on suggestions from
Jakob Schlyter.

## Version 00
  - First rough version
