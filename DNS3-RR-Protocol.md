% title = "Third Party DNS operator to Registars/Registries Protocol" 
% abbrev = "3-DNS-RRR" 
% category = "info"
% ipr="trust200902"
% docName = "draft-ogud-dnsoperator-to-RRR-protocol-00"
% area = "Applications" 
% workgroup = ""
% keyword = ["dnssec", "delegation maintainance", "trust anchors"]
%
% date = 2015-08-30T00:00:00Z
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
%
% [[author]]
% fullname="Matthew Pounsett" 
% initials="M."
% surname="Pounsett"
% organization="Rightside"
%  [author.address] 
%   street="Toronto, ON"
%   email="matt.pounsett@rightside.co"
% [[author]]
% fullname = "Jacques LaTour" 
% organization="CIRA"
%  [author.address] 
%   street="Ontario,ON" 
%   email="jacques.latour@cira.ca"

.# Abstract
There are several problems that arise in the standard
Registrant/Registrar/Registry model when the operator of a zone is
neither the Registrant nor the Registrar for the delegation.  Historically
the issues have been minor, and limited to difficulty guiding the
Registrant through the initial changes to the NS records for the
delegation.  As this is usually a one-off activity when the operator first
takes charge of the zone it has not been treated as a serious issue.

With the rise of DNSSEC it has become necessary for the Registrant in this
situation to make regular (often annual) changes to the delegation in
order to manage KSK rolls, by updating the delegation's DS record(s).
Under the current model this is prone to Registrant error and significant
delays.

There is a need for a simple protocol which would allow a third party DNS
operator to update DS and NS records for a delegation without involving
the registrant in each operation.

The protocol described in this draft is REST based, and when used through
an authenticated channel can be used to bootstrap DNSSEC.  Once DNSSEC is
established this channel can be used to trigger maintenance of delegation
records such as DS, NS, and glue records.   The protocol is kept simple
and flexible in order to accomodate different operating models.

{mainmatter}

# Introduction
Wwhy is this needed ? Current system does not work well

## Notational Conventions
The key words "MUST", "MUST NOT", "REQUIRED", "SHALL",
"SHALL NOT", "SHOULD", "SHOULD NOT", "RECOMMENDED", "MAY", and
"OPTIONAL" in this document are to be interpreted as described
in [@RFC2119].

    
# Definitions
For the purposes of this draft, a third-party DNS operator is any
DNS operator responsible for a zone where the operator is neither
the Registrant nor the Registrar of record for the delegation.

# OP-3-DNS-RR Protocol
The basic call is 
      <SERVER><cmd>/domain/auth=""/extra-stuff 

##Commands 
The commands can be:

  "/getDS"  install DS from CDS/CDNSKEY at domain present and different from current DS set

  "/getNS"  update NS set based on the childs NS set 

  "/delDS"  delete the all DS records at domain (how to authorize is a question)

  "/status"  Returns the current NS and DS + glue records for the domain and or any other status information

The commands "getDS" and "status" are required, the support for others is
RECOMMENDED. The following options to the commands are allowed

   "auth="   an authenticaion token

   "debug="  request a debug session
  

## Answers
The basic answer is a jason blob the important parts of the blob are 

   "refer:"  will contain an URI; this is an referal to an URI that is better able to do execute the command

   "refused:"  This command can not be executed, and the reason is inside the block

   "debug:"  list of debug messages normally empty unless debug flag is 
present, this section should be ignored in normal processing

   "error:"  if there was one look inside debug for more details

   "domain:" what domain this is an answer for this section MUST be included in all answers

   "rr:"  the new list of rrs "can be empty" 

   "challenge:" an RR to insert into the zone 

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

#Security considerations

TBD


# IANA Actions
URI ??? TBD


# Internationalization Considerations
This protcol is designed for machine to machine communications </t> 

{backmatter}

# Document History
First rough version


