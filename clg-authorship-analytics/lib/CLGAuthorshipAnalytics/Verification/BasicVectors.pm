package CLGAuthorshipAnalytics::Verification::BasicVectors;

#twdoc
#
# "Basic" verification strategy: simply computes the similarity between two documents according to a sim measure, for a set of observation types.
#
# ---
#
# EM December 2015
# 
#/twdoc


use strict;
use warnings;
use Carp;
use Log::Log4perl;
use Data::Dumper;
use CLGTextTools::Stats qw/pickInList pickNSloppy aggregateVector/;
use CLGTextTools::Commons qw/assignDefaultAndWarnIfUndef/;
use CLGAuthorshipAnalytics::Verification::VerifStrategy;
use CLGTextTools::Logging qw/confessLog cluckLog/;
use CLGTextTools::SimMeasures::Measure qw/createSimMeasureFromId/;
our @ISA=qw/CLGAuthorshipAnalytics::Verification::VerifStrategy/;

use base 'Exporter';
our @EXPORT_OK = qw//;





#twdoc new($class, $params)
#
# $params:
#
# * logging
# * obsTypesList 
# * simMeasure:  a ``CLGTextTools::Measure`` object (initialized) (default minMax)
# * multipleProbeAggregate: random,  median, arithm, geom, harmo. If there are more than one probe doc on either side (or both), specifies which method should be used to aggregate the similarity scores. If "random" (default), then a default doc is picked among the list (disadvantage: same input can give different results). Otherwise the similarity is computed between all pairs (cartesian product ~NxM), and the values are aggregated according to the parameter (disadvantage: ~NxM longer).
#
#/twdoc
#
sub new {
    my ($class, $params) = @_;
    my $self = $class->SUPER::new($params,__PACKAGE__);
    $self->{obsTypesList} = $params->{obsTypesList};
    $self->{simMeasure} = createSimMeasureFromId(assignDefaultAndWarnIfUndef("simMeasure", $params->{simMeasure}, "minmax", $self->{logger}), $params, 1); 
    $self->{multipleProbeAggregate} =  assignDefaultAndWarnIfUndef("multipleProbeAggregate", $params->{multipleProbeAggregate}, "random", $self->{logger}) ;
    bless($self, $class);
    return $self;
}



#twdoc compute($self, $probeDocsLists)
#
# see parent.
#
# * $probeDocsLists: [ [docA1, docA2, ...] ,  [docB1, docB2,...] ]
# ** where docX = ``DocProvider``
#/twdoc
#
sub compute {
    my $self = shift;
    my $probeDocsLists = shift;



    my @features;
    $self->{logger}->debug("Basic strategy: computing features between pair of sets of docs") if ($self->{logger});
    confessLog($self->{logger}, "Cannot process case: no obs types at all") if ((scalar(@{$self->{obsTypesList}})==0) && $self->{logger});
    foreach my $obsType (sort @{$self->{obsTypesList}}) {
	$self->{logger}->debug("computing similarity for obs type '$obsType'") if ($self->{logger});
	my $simValue;
	if ($self->{multipleProbeAggregate} eq "random") {
	    $self->{logger}->debug("random mode: picking a pair of docs") if ($self->{logger});
	    my @probeDocPair = map { pickInList($_) } @$probeDocsLists;
	    
		    my $content1 = $probeDocPair[0]->getObservations($obsType);
		    my $content2 = $probeDocPair[1]->getObservations($obsType);
		    
		    # DEBUG
		    my ($aword,$avalue) = each(%$content1);
		    $self->{logger}->trace("basicVectors.compute: showing just the first value for obs '$aword': ".Dumper($avalue))  if ($self->{logger});
		    my $simValue = 8; # dummy result
		    
	    
	} else {
	    my @values;
	    $self->{logger}->debug("iterating all the pairs of docs") if ($self->{logger});
	    foreach my $doc1 (@{$probeDocsLists->[0]}) {
		foreach my $doc2 (@{$probeDocsLists->[1]}) {
		    my $content1 = $doc1->getObservations($obsType);
		    my $content2 = $doc2->getObservations($obsType);
		    
		    # DEBUG
		    my ($aword,$avalue) = each(%$content1);
		    $self->{logger}->trace("basicVectors.compute: showing just the first value for obs '$aword': ".Dumper($avalue))  if ($self->{logger});
		    my $res = 8; # dummy result
		    
		    push(@values, $res);
		}
	    }
	    $simValue = aggregateVector(\@values, $self->{multipleProbeAggregate});
	    $simValue = 0 if (!defined($simValue)); # todo: questionable simplification, maybe should be NaN?
	}
	$self->{logger}->debug("similarity value for '$obsType' = $simValue") if ($self->{logger});
	push(@features, $simValue);
    }

    return \@features;
}


sub featuresHeader {
    my $self = shift;

    my @names;
    foreach my $obsType (sort @{$self->{obsTypesList}}) {
	push(@names, $obsType);
    }
    return \@names;
}


1;
