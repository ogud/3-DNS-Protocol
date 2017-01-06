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

When the domain on the other hand uses DNSSEC it necessary to make regular 
(sometimes annual) changes to the delegation, in order to track KSK rollover, 
by updating the delegation's DS record(s).
Under the current model this is prone to delays and errors. Even when the Registrant has 
outsourced the operation of DNS to a third party the registrant still has to 
be in the loop to update the DS record. 

There is a need for a simple protocol that allows a third party DNS operator
to update DS and NS records in a trusted manner for a delegation without
involving the registrant for each operation. This same protocol can be used by
Registrants. 

The protocol described in this draft is REST based, and when used through an
authenticated channel can be used to establish the DNSSEC Initial Trust (to
turn on DNSSEC or bootstrap DNSSEC). Once DNSSEC trust is established this
channel can be used to trigger maintenance of delegation records such as DS,
NS, and glue records. The protocol is kept as simple as possible.

{mainmatter}

# Introduction

Why is this needed?  DNS registration systems today are designed around making
registrations easy and fast. After the domain has been registered there
are really three options on who maintains the DNS zone that is loaded on the
"primary" DNS servers for the domain this can be the Registrant, Registrar, or
a third party DNS Operator.

Unfortunately the ease to make changes differs for each one of these options.
The Registrant needs to use the interface that the registrar provides to
update NS and DS records. The Registrar on the other hand can make changes
directly into the registration system. The third party DNS Operator on the
hand needs to go through the Registrant to update any delegation information.

Current system does not work well, there are many types of failures have been 
reported and they have been at all levels in the registration model. 

The failures result either inability to use DNSSEC or in validation failures
that cause the domain to become invalid and all users that are behind
validating resolvers will not be able to to access the domain.

The goal of this document is to create an automated interface that will reduce the 
friction in maintaining DNSSEC delegations.

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
The primary goal is to have a protocol to establish a secure chain of trust
that involves parties that are not in the traditional Registrant/Registrar/Registry (RRR) model.

A DNS operator cannot easily and scalably identify the registrar (or registration agent, or reseller)
for a domain name it is operating.  Thus the DNS operator has to fallback to relying on the registrant (as customer)
of the services to establish a secure chain of trust.

In the general case there should be a way to find the right Registrar/Registry
entity to talk to, but it does not exist. Whois[] is the natural protocol to
carry such information but that protocol but is unreliable and hard to parse. Its
proposed successor RDAP [@RFC7480] has yet be deployed on most TLD's.

The preferred communication mechanism is to use is to use a REST [@RFC6690]
call to start processing of the requested delegation information.

## How does a child signal its parent it wants to establish a secure chain of trust?
The child needs first to sign the domain, then the child can "upload" the DS record to
its parent. The "normal" way to upload a DS record is for the registrant to go through registration 
interface and submit a DS record (or DNSKEY or both), but a lack of registrar/reseller DNSSEC support in sufficient frequency
is a significant operational problem to the detriment of DNSSEC adoption.

The DNS Operator may not have access to the interface thus the registrant needs to relay the information. For large
operations this does not scale, as evident in lack of Trust Anchors for signed
deployments that are operated by third parties.

The child can signal its desire to have DNSSEC validation enabled by
publishing one of the special DNS records CDS and/or CDNSKEY[@!RFC7344] and
its proposed extension [@!I-D.ietf-dnsop-maintain-ds#03].

Once the "parent" "sees" these records it SHOULD start acceptance processing.
This document covers how to make the CDS records visible to the
right parental agent.

This document and [@I-D.ogud-dnsop-maintain-ds#00] argue that the publication of
CDS/CDNSKEY record is sufficient for the parent to start the acceptance
processing. The main point is to provide authentication thus if the child is
in "good" state then the DS upload should be simple to accept and publish. If
there is any problem the parent does not add the DS.

In the event this protocols and its associated authentication mechanism does not
address the Registrant's security requirements to create a secure delegation then
the Registrant always has recourse by submitting its DS record via its registration interface. 

## How does a parental agent detects maintenance activities
One the secure chain of trust is established, the parent should implement a system to
automate domain polling for CDS maintenance record changes. The maintenance activities
includes adding or removing DS record(s) [@I-D.ogud-dnsop-maintain-ds#00].  

Each parental agent is responsible to develop and implement and communicate their
DNSSEC maintenance policies.

## What checks are needed by parent?
The parent upon receiving a signal or detecting through polling that the child desires
to have its DS record published. The basic tests include,
    1. Is the zone is properly signed as per the parent DNSSEC policy 
    2. The zone has a CDS signed by a KSK referenced in the current CDS,
       referring to a at least one key in the current DNSKEY RRset
    3. All the name-servers for the zone agree on the CDS RRset contents

NOTE:(do we need a new section in the DPS for the CDS management policy [@RFC6841]?)
	
Parents can perform additional tests, defined delays, queries over TCP, ensure zone
delegation best practice as per [@!I-D.wallstrom-dnsop-dns-delegation-requirements#00] and even
ask the DNS Operator to prove they can add data to the zone, or provide a code
that is tied to the affected zone. The protocol is partially-synchronous,
i.e. the server can elect to hold connection open until the operation has
concluded or it can return that it received the request. It is up to the child
to monitor the parent for completion of the operation and issue possible
follow-up calls.

The parent can have a policy to accept a CDS signed by a ZSK or a CSK. The parent should not
make any changes to DS RRset if the child name-servers do not agree on content.

# Third Party DNS operator to Registrars/Registries RESTful API
The specification of this API is minimalist, but a realistic one. 

This API may be denied access to change the DS records for domains that are Registry Locked 
(HTTP Status code 401).  Registry Lock is a mechanisms provided by certain registries or registrars
that prevents domain hijacking by ensuring no attributes of the domain are changeable and no 
transfer or deletion transactions can be processed against the domain name may prevents certain
attributes in the registry to be changed (locks).  

## API Authentication
The API does not impose any unique server authentication requirements. The
server authentication provided by TLS fully addresses the needs. The API
MUST be provided over TLS-protected transport (e.g., HTTPS) or VPN.

## API Authorization
Authorization to access the API is outside the scope of this document.
The publication of CDS record(s) in the child zone file are indications of intention 
to perform DS records activities (add/delete) for the domain in the parent zone. 
This means the proceeding of the API action is not determined by who issued the API 
request but by the intention in the CDS publication. 
Therefore, authorization is out of scope. Registries and registrars who plan to provide this service can,
however, implement their own policy to protect access to the API such as IP white listing, API key, etc.

## API Base URL Locator

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

#### Response
   - HTTP Status code 201 indicates a success.
   - HTTP Status code 400 indicates a failure due to validation.
   - HTTP Status code 401 indicates an unauthorized resource access.
   - HTTP Status code 403 indicates a failure due to an invalid challenge token.
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.


### Removing a DS (turn off DNSSEC)
#### Request
    Syntax: DELETE /domains/{domain}/cds

A null CDS or CDNSKEY record mean the entire DS RRset must be removed.

#### Response
   - HTTP Status code 200 indicates a success.
   - HTTP Status code 400 indicates a failure due to validation.
   - HTTP Status code 401 indicates an unauthorized resource access.
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.

### DS Maintenance 
#### Request
    Syntax: PUT /domains/{domain}/cds

Maintenance activities are performed based on the CDS available in the child zone.
DS records may be added, removed. But the entire DS RRset must not be deleted.

#### Response
   - HTTP Status code 200 indicates a success.
   - HTTP Status code 400 indicates a failure due to validation.
   - HTTP Status code 401 indicates an unauthorized resource access.
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.

## Tokens resource
   Path: /domains/{domain}/tokens
   {domain}: is the domain name to be operated on

### Setup Initial Trust Establishment with Challenge
#### Request
    Syntax: POST /domains/{domain}/tokens

The parent's DNSSEC policy may require proof the DNS Operator is in control of the domain.  
The token API call returns a random token to be included as a _delegate TXT record prior establishing the
DNSSEC initial trust. This is an additional trust control mechanism to establish the initial chain of trust. 
Note that the _delegate TXT record is publicly available and not a secret token.


#### Response
   - HTTP Status code 200 indicates a success.  Token included in the body of the response,
     as a valid TXT record
   - HTTP Status code 404 indicates the domain does not exist.
   - HTTP Status code 500 indicates a failure due to unforeseeable reasons.


## Customized Error Messages
Service providers can provide a customized error message in the response body
in addition to the HTTP status code defined in the previous section.

This can include an Identifying number/string that can be used to track the
requests.

#Using the definitions
This section at the moment contains comments from early implementers

## How to react to 403 on POST cds
The basic reaction to a 403 on POST /domains/{domain}/cds is to issue POST /domains/{domain}/tokens
command to fetch the challenge to insert into the zone.

# Security considerations

When domains are provisioned with good Internet hygiene and zone delegation follows best 
practice such as [@!I-D.wallstrom-dnsop-dns-delegation-requirements#00], the registrar or registry can
then trust the DNS information it queried over two different ASN and over TCP to establish the initial chain of trust.

In addition, the registrar or registry can required the DNS Operator to prove they control the zone 
by adding a challenge token a to the zone.

This protocol should increase the adoption of DNSSEC and get more zones to become
validated thus overall the security gain outweighs the possible drawbacks.

Registrant and DNS Operator always have the option to establish the chain of trust in band via the 
standard Registrant/Registrar/Registry model.


# IANA Actions
URI ??? TBD


# Internationalization Considerations
This protocol is designed for machine to machine communications

{backmatter}

# Document History

## Regex version 02 
Clarified based on comments and questions from early implementors (JL)
Text edits and clarifications. 

## Regex version 01 
Rewrote Abstract and Into (MP) 
Introduced code 401 when changes are not allowed 
Text edits and clarifications. 

## Regex version 00 
Working group document same as 03, just track changed to standard

## Version 03
Clarified based on comments and questions from early implementors

## Version 02
Reflected comments on mailing lists

## Version 01
This version adds a full REST definition this is based on suggestions from
Jakob Schlyter.


## Version 00
First rough version


