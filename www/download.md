${ var doc = require( "hopdoc" ) }
${ var config = require( hop.config ) }
${ var xml = require( "./xml.js" ) }
${ var cfg = require( "./doc.json" ) }

Getting Bigloo
--------------

Current and older Bigloo source files are all available bundled in
tarball files at:
[ftp://ftp-sop.inria.fr/indes/fp/Bigloo](ftp://ftp-sop.inria.fr/indes/fp/Bigloo)


${<div class="row">
  <div class="col-xs-4">
    <xml.downloadButton
       class="success"
       title="Stable"
       icon="glyphicon-download"
	   label=${"bigloo-stable.tgz (" + cfg.version + ")"}
       href=${cfg.bglurlbase + "/bigloo-stable.tar.gz"}/>
  </div>
  <div class="col-xs-4">
    <xml.downloadButton
       class="warning"
       title="Unstable"
       icon="glyphicon-download"
	   label="bigloo-unstable.tgz"
       href=${cfg.bglurlbase + "/bigloo-unstable.tar.gz"}/>
  </div>
  <div class="col-xs-4">
    <xml.downloadButton
       class="danger"
       title="Github"
       icon="glyphicon-cloud-download"
	   label="github"
       href=${cfg.github}/>
  </div>
</div>}

[Debian/Ubuntu](./debian.html) and [OS X](./homebrew.html) users might
avoid the hassle of installing manually Bigloo by using pre-compiled
versions.

${doc.include( "../INSTALL.md" )}
