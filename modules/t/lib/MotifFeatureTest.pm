=head1 LICENSE

    Copyright [1999-2015] Wellcome Trust Sanger Institute and the EMBL-European Bioinformatics Institute
    Copyright [2016-2019] EMBL-European Bioinformatics Institute

    Licensed under the Apache License, Version 2.0 (the "License");
you may not use this file except in compliance with the License.
    You may obtain a copy of the License at

        http://www.apache.org/licenses/LICENSE-2.0

Unless required by applicable law or agreed to in writing, software
    distributed under the License is distributed on an "AS IS" BASIS,
                                                               WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
    See the License for the specific language governing permissions and
    limitations under the License.

=head1 CONTACT

  Please email comments or questions to the public Ensembl
  developers list at <http://lists.ensembl.org/mailman/listinfo/dev>.

  Questions may also be sent to the Ensembl help desk at
  <http://www.ensembl.org/Help/Contact>.

=cut

package MotifFeatureTest;

use strict;
use warnings;

use Test::More;
use Test::Exception;

use parent qw(Bio::EnsEMBL::Funcgen::Test);

sub parameters :Test(setup) {
    my $self = shift;

    my $binding_matrix =
        $self->{funcgen_db}->get_adaptor('BindingMatrix')->fetch_by_dbID(134);

    my %mandatory_constructor_parameters = (
        -score          => 100,
        -binding_matrix => $binding_matrix
    );

    $self->{mandatory_constructor_parameters} =
        \%mandatory_constructor_parameters;

    my $slice =
        $self->{core_db}->get_adaptor('Slice')->fetch_by_seq_region_id(131539);

    my %optional_constructor_parameters = (
        -slice     => $slice,
        -stable_id => 'ENSM00000000000',
        -start     => 1,
        -end       => 15,
        -strand    => 1
    );

    my %constructor_parameters = (%mandatory_constructor_parameters,
                                  %optional_constructor_parameters);

    $self->{constructor_parameters} = \%constructor_parameters;

    my $epigenome =
        $self->{funcgen_db}->get_adaptor('Epigenome')->fetch_by_dbID(126);

    my %parameters = (
        'epigenome' => $epigenome,
        'position'  => 4
    );

    $self->{parameters} = \%parameters;
}

sub define_expected :Test(setup) {
    my $self = shift;

    my $binding_matrix =
        $self->{funcgen_db}->get_adaptor('BindingMatrix')->fetch_by_dbID(134);

    my $peak =
        $self->{funcgen_db}->get_adaptor('Peak')->fetch_by_dbID(95922119);

    my $epigenomes =
        $self->{funcgen_db}->get_adaptor('Epigenome')
             ->fetch_all_by_dbID_list([ 126, 131, 132, 153, 155, 165, 176 ]);


    $self->{expected} = {
        'binding_matrix'          => $binding_matrix,
        'score'                   => 6.85690955393,
        'stable_id'               => 'ENSM00205163537',
        'number_of_peaks'         => 7,
        'peaks'                   => [ $peak ],
        'epigenomes'              => $epigenomes,
        'is_position_informative' => 1,
        'is_verified'             => 1,
    };

    my $tfc =

    my %summary = (
        'binding_matrix'                        => $binding_matrix->name(),
        'start'                                 => 5197613,
        'end'                                   => 5197629,
        'strand'                                => -1,
        'seq_region_name'                       => 3,
        'stable_id'                             => $self->{expected}->{stable_id},
        'score'                                 => $self->{expected}->{score},
        'transcription_factor_complex'          => 'ETV2::CEBPD,ETV2::TEF,'
                                                    . 'ERF::CEBPD,ELK1::TEF,'
                                                    . 'FLI1::CEBPB,FLI1::CEBPD,'
                                                    . 'ETV5::CEBPD',
        'epigenomes_with_experimental_evidence' => 'HeLa-S3,GM12878,K562,'
                                                    . 'HepG2,IMR 90,'
                                                    . 'H1 hESC ENCSR820QMS,'
                                                    . 'HCT116'
    );

    $self->{expected}->{summary} = \%summary;
}

sub fetch_from_test_db :Test(setup) {
    my $self = shift;

    my $short_class = $self->short_class();

    $self->{fetched}->{$short_class} =
        $self->{funcgen_db}->get_adaptor($short_class)->fetch_by_dbID(4);
}

sub getters {
    return [ 'binding_matrix', 'score', 'stable_id' ];
}

sub get_BindingMatrix :Test(1) {
    my $self = shift;

    my $short_class = $self->short_class();

    is_deeply($self->{fetched}->{$short_class}->get_BindingMatrix,
              $self->{expected}->{binding_matrix},
              'get_BindingMatrix works'
    );
}

sub get_all_overlapping_Peaks :Test(no_plan) {
    my $self = shift;

    my $short_class = $self->short_class();

    my @peaks = @{$self->{fetched}->{$short_class}->get_all_overlapping_Peaks};

    $self->num_tests(scalar(@peaks) + 1);

    for my $peak (@peaks) {
        isa_ok($peak, 'Bio::EnsEMBL::Funcgen::Peak');
    }

    is(scalar @peaks,
       $self->{expected}->{number_of_peaks},
       'get_all_overlapping_Peaks works');
}

sub fetch_all_overlapping_Peaks :Test(no_plan) {
    my $self = shift;

    my $short_class = $self->short_class();

    my @peaks =
        @{$self->{fetched}->{$short_class}->fetch_all_overlapping_Peaks};

    $self->num_tests(scalar(@peaks) + 1);

    for my $peak (@peaks) {
        isa_ok($peak, 'Bio::EnsEMBL::Funcgen::Peak');
    }

    is(scalar @peaks,
       $self->{expected}->{number_of_peaks},
       'fetch_all_overlapping_Peaks works');
}

sub get_all_overlapping_Peaks_by_Epigenome :Test(1) {
    my $self        = shift;
    my $short_class = $self->short_class();

    my $epigenome = $self->{parameters}->{epigenome};

    my $peak = $self->{fetched}->{$short_class}->
        get_all_overlapping_Peaks_by_Epigenome($epigenome);

    is_deeply($peak,
              $self->{expected}->{peaks},
              'get_all_overlapping_Peaks_by_Epigenome() works'
    );
}

sub fetch_overlapping_Peak_by_Epigenome :Test(1) {
    my $self        = shift;
    my $short_class = $self->short_class();

    my $epigenome = $self->{parameters}->{epigenome};

    my $peak = $self->{fetched}->{$short_class}->
        fetch_overlapping_Peak_by_Epigenome($epigenome);

    is_deeply($peak,
              $self->{expected}->{peaks}->[0],
              'fetch_overlapping_Peak_by_Epigenome() works'
    );
}

sub is_experimentally_verified_in_Epigenome :Test(1) {
    my $self = shift;
    my $short_class = $self->short_class();

    my $epigenome = $self->{parameters}->{epigenome};

    my $is_verified = $self->{fetched}->{$short_class}->
        is_experimentally_verified_in_Epigenome($epigenome);

    is ($is_verified,
        $self->{expected}->{is_verified},
        'is_experimentally_verified_in_Epigenome() works'
    );

    # TODO test false
}

sub get_all_Epigenomes_with_experimental_evidence :Test(1) {
    my $self        = shift;
    my $short_class = $self->short_class;
    my $epigenomes  = $self->{fetched}->{$short_class}
                           ->get_all_Epigenomes_with_experimental_evidence;
    is_deeply($epigenomes,
              $self->{expected}->{epigenomes},
              'get_all_Epigenomes_with_experimental_evidence() works');
}

sub is_position_informative :Test(1){
    my $self = shift;

    my $short_class = $self->short_class;
    my $pos         = $self->{parameters}->{position};
    is($self->{fetched}->{$short_class}->is_position_informative($pos),
       $self->{expected}->{is_position_informative},
       'is_position_informative() works'
    );
}

sub infer_variation_consequence :Test(no_plan){
    #TODO write tests
}

1;