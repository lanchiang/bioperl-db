

# conventions:
# <table_name>_id is primary internal id (usually autogenerated)

# author Ewan Birney 
# comments to bioperl - bioperl-l@bioperl.org

# database have bioentries. That is about it.
# we do not store different versions of a database as different dbids
# (there is no concept of versions of database). There is a concept of
# versions of entries. Versions of databases deserve their own table and
# join to bioentry table for tracking with versions of entries 


CREATE TABLE biodatabase (
  biodatabase_id int(10) unsigned NOT NULL auto_increment,
  name        varchar(40) NOT NULL,
  PRIMARY KEY(biodatabase_id)
);

# we could insist that taxa are NCBI taxa id, but on reflection I made this
# an optional extra line, as many flat file formats do not have the NCBI id

# full lineage is : delimited string starting with species.

# no organelle/sub species

CREATE TABLE taxa (
  taxa_id   int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  full_lineage mediumtext NOT NULL,
  common_name varchar(255) NOT NULL,
  ncbi_taxa_id int(10)
  
);


# we can be a bioentry without a biosequence, but not visa-versa
# most things are going to be keyed off bioentry_id

# accession is the stable id, display_id is a potentially volatile,
# human readable name.


CREATE TABLE bioentry (
  bioentry_id  int(10) unsigned NOT NULL auto_increment,
  biodatabase_id  int(10) NOT NULL,
  display_id   varchar(40) NOT NULL,
  accession    varchar(40) NOT NULL,
  entry_version int(10) NOT NULL, 
  division     varchar(3) NOT NULL,
  UNIQUE (biodatabase_id,accession,entry_version),
  FOREIGN KEY (biodatabase_id) REFERENCES biodatabase(biodatabase_id),
  PRIMARY KEY(bioentry_id)
);

#Bioentries should have one or more dates

CREATE TABLE bioentry_date (
  bioentry_id int(10) NOT NULL,
  date varchar(200) NOT NULL,
  FOREIGN KEY (bioentry_id) REFERENCES bioentry(bioentry_id),
  PRIMARY KEY(bioentry_id,date)
);

# not all entries have a taxa, but many do.
# one bioentry only has one taxa! (weirdo chimerias are not handled. tough)

CREATE TABLE bioentry_taxa (
  bioentry_id int(10)  NOT NULL,
  taxa_id     int(10)  NOT NULL,
  FOREIGN KEY (bioentry_id) REFERENCES bioentry(bioentry_id),
  PRIMARY KEY(bioentry_id)
);

# some bioentries will have a sequence
# biosequence because sequence is sometimes 
# a reserved word

CREATE TABLE biosequence (
  biosequence_id  int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  bioentry_id     int(10) NOT NULL,
  seq_version     int(6) NOT NULL,
  biosequence_str mediumtext NOT NULL,
  molecule        varchar(10),
  FOREIGN KEY (bioentry_id) REFERENCES bioentry(bioentry_id),
  UNIQUE(bioentry_id)
);


# Direct links. It is tempting to do this
# from bioentry_id to bioentry_id. But that wont work
# during updates of one database - we will have to edit
# this table each time. Better to do the join through accession
# and db each time. Should be almost as cheap

# [note - should we normalise this into a dbxref table?
#  should be faster as we can join by integer ids]
CREATE TABLE bioentry_direct_links (
       bio_dblink_id           int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
       source_bioentry_id      int(10) NOT NULL,
       dbname                  varchar(40) NOT NULL,
       accession               varchar(40) NOT NULL,
       FOREIGN KEY (source_bioentry_id) REFERENCES bioentry(bioentry_id)
);

#We can have multiple references per bioentry, but one reference
#can also be used for the same bioentry.

CREATE TABLE reference (
  reference_id       int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  reference_location varchar(255) NOT NULL,
  reference_title    mediumtext NOT NULL,
  reference_authors  mediumtext NOT NULL,
  reference_medline  int(10) NOT NULL

);

CREATE INDEX medlineidx ON reference(reference_medline);

CREATE TABLE bioentry_reference (
  bioentry_id int(10) unsigned NOT NULL,
  reference_id int(10) unsigned NOT NULL,
  reference_start    int(10),
  reference_end      int(10),
  reference_rank int(5) unsigned NOT NULL,

  PRIMARY KEY(bioentry_id,reference_id,reference_rank),
  FOREIGN KEY(bioentry_id) REFERENCES bioentry(bioentry_id),
  FOREIGN KEY(reference_id) REFERENCES reference(reference_id)
);
CREATE INDEX reference_rank_idx ON bioentry_reference(reference_rank);

# We can have multiple comments per seqentry, and
# comments can have embedded '\n' characters

CREATE TABLE comment (
  comment_id  int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
  bioentry_id    int(10) NOT NULL,
  comment_text   mediumtext NOT NULL,
  comment_rank   int(5) NOT NULL,
  FOREIGN KEY(bioentry_id) REFERENCES bioentry(bioentry_id)
);

# separate description table separate to save on space when we
# do not store descriptions

CREATE TABLE bioentry_description (
   bioentry_id   int(10) unsigned NOT NULL,
   description   varchar(255) NOT NULL,
   FOREIGN KEY(bioentry_id) REFERENCES bioentry(bioentry_id)
);


# separate keyword table

CREATE TABLE bioentry_keywords (
  bioentry_id   int(10) unsigned NOT NULL,
  keywords      varchar(255) NOT NULL,
  FOREIGN KEY (bioentry_id) REFERENCES bioentry(bioentry_id),
  PRIMARY KEY(bioentry_id)
);

# feature table. We cleanly handle
#   - simple locations
#   - split locations
#   - split locations on remote sequences

# The fuzzies are not handled yet

# we expect to share both qualifiers and keys between features. As well as saving
# on dataspace and query time, making this more normalised is a "good thing"

CREATE TABLE seqfeature_qualifier (
       seqfeature_qualifier_id int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
       FOREIGN KEY (seqfeature_qualifier_id) REFERENCES seqfeature_qualifier(seqfeature_qualifier_id),
       qualifier_name varchar(255) NOT NULL
);

CREATE TABLE seqfeature_key (
       seqfeature_key_id int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
       key_name varchar(255) NOT NULL
);

CREATE TABLE seqfeature_source (
       seqfeature_source_id int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
       source_name varchar(255) NOT NULL
);

CREATE TABLE seqfeature (
   seqfeature_id int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
   bioentry_id   int(10) NOT NULL,
   seqfeature_key_id     int(10),
   seqfeature_source_id  int(10),
   seqfeature_rank int(5),
  FOREIGN KEY (seqfeature_source_id) REFERENCES seqfeature_source(seqfeature_source_id),
  FOREIGN KEY (bioentry_id) REFERENCES bioentry(bioentry_id)
);

CREATE TABLE seqfeature_qualifier_value (
   seqfeature_id int(10) NOT NULL,
   seqfeature_qualifier_id int(10) NOT NULL,
   seqfeature_qualifier_rank int(5) NOT NULL,
   qualifier_value  mediumtext NOT NULL,
  FOREIGN KEY (seqfeature_qualifier_id) REFERENCES seqfeature_qualifier(seqfeature_qualifier_id),
   PRIMARY KEY(seqfeature_id,seqfeature_qualifier_id,seqfeature_qualifier_rank)
);
   
# basically we model everything as potentially having
# any number of locations, ie, a split location. SimpleLocations
# just have one location. We need to have a location id so for remote
# split locations we can specify the start/end point

# please do not try to model complex assemblies with this thing. It wont
# work. Check out the ensembl schema for this.

# we allow nulls for start/end - this is useful for fuzzies as
# standard range queries will not be included
CREATE TABLE seqfeature_location (
   seqfeature_location_id int(10) unsigned NOT NULL PRIMARY KEY auto_increment,
   seqfeature_id          int(10) NOT NULL,
   seq_start              int(10),
   seq_end                int(10),
   seq_strand             int(1)  NOT NULL,
   location_rank          int(5)  NOT NULL,
  FOREIGN KEY (seqfeature_id) REFERENCES seqfeature(seqfeature_id)
);

# for remote locations, this is the join to make.
# beware - in the object layer it has to make a double SQL query to figure out
# whether this is remote location or not

# like DR links, we do not link directly to a bioentry_id - we have to do
# this run-time

CREATE TABLE remote_seqfeature_name (
       seqfeature_location_id int(10) unsigned NOT NULL PRIMARY KEY,
       accession varchar(40) NOT NULL,
       version   int(10) NOT NULL,
  FOREIGN KEY (seqfeature_location_id) REFERENCES seqfeature_location(seqfeature_location_id)
);

# location qualifiers - mainly intended for fuzzies but anything
# can go in here
# some controlled vocab terms have slots;
# fuzzies could be modeled as min_start(5), max_start(5)
# 
# there is no restriction on extending the fuzzy ontology
# for your own nefarious aims, although the bio* apis will
# most likely ignore these
CREATE TABLE location_qualifier_value (
   seqfeature_location_id int(10) unsigned NOT NULL,
   seqfeature_qualifier_id int(10) NOT NULL,
   qualifier_value  char(255) NOT NULL,
   slot_value int(10),
  FOREIGN KEY (seqfeature_location_id) REFERENCES seqfeature_location(seqfeature_location_id)
);

# pre-make the fuzzy ontology
INSERT INTO seqfeature_qualifier (qualifier_name) VALUES ('min-start');
INSERT INTO seqfeature_qualifier (qualifier_name) VALUES ('min-end');
INSERT INTO seqfeature_qualifier (qualifier_name) VALUES ('max-start');
INSERT INTO seqfeature_qualifier (qualifier_name) VALUES ('max-end');
INSERT INTO seqfeature_qualifier (qualifier_name) VALUES ('unknown-start');
INSERT INTO seqfeature_qualifier (qualifier_name) VALUES ('unknown-end');
INSERT INTO seqfeature_qualifier (qualifier_name) VALUES ('unbounded-start');
INSERT INTO seqfeature_qualifier (qualifier_name) VALUES ('unbounded-end');
# coordinate policies?

#
# this is a tiny table to allow a cach'ing corba server to
# persistently store aspects of the root server - so when/if
# the server gets reaped it can reconnect
#

CREATE TABLE cache_corba_support (
       biodatabase_id    int(10) unsigned NOT NULL PRIMARY KEY,  
       http_ior_string   varchar(255),
       direct_ior_string varchar(255)
       );




