use utf8;
use strict;
use Test::More tests => 34;
use WebServiceClient;
use WebServiceConfiguration qw( WEBSERVICE_URL WEBSERVICE_USER WEBSERVICE_SHOP_PATH);
use WebServiceTools qw( TLocalizedString TAttributes hLocalizedString hAttributes cmpDateTime );

my $CatalogService = WebServiceClient
    ->uri( 'urn://epages.de/WebService/CatalogService/2005/01' )
    ->proxy( WEBSERVICE_URL )
    ->userinfo( WEBSERVICE_USER )
    ->xmlschema('2001');

# Sets all the required prerequisites for the tests. Will be called before the test are run.
my %Options = (
    'Alias'     => 'perl_test-1',
    'Path'      => 'Categories',
    'Name_in'   => {
        'de'    => 'Mein Katalogname',
        'en'    => 'my catalog name',
    },
    'Name_up'   => {
        'de'    => 'Mein geänderter Katalogname',
        'en'    => 'my updated catalog name',
    },
    'Attr_in'   => {
        'Date'  => '2005-12-24T10:00:00',
    },
    'Attr_up'   => {
        'Date'  => '2005-12-24T18:00:00',
    },
);
$Options{'FullPath'} = "$Options{'Path'}/$Options{'Alias'}";

my $Catalog_in      = {
    'Alias'         => $Options{'Alias'},
    'ParentCatalog' => $Options{'Path'},
    'Name'          => TLocalizedString( $Options{'Name_in'} ),
    'Attributes'    => TAttributes(      $Options{'Attr_in'} ),
};

my $Catalog_update  = {
    'Path'          => $Options{'FullPath'},
    'Name'          => TLocalizedString( $Options{'Name_up'} ),
    'Attributes'    => TAttributes(      $Options{'Attr_up'} ),
};

# Create a Catalog and check if the creation was successful
sub testCreate {

    my $ahResults = $CatalogService->create( [$Catalog_in] )->result;
    is( scalar @$ahResults, 1, 'create result count' );

    my $hResult = $ahResults->[0];
    ok( !$hResult->{'Error'}, 'create: no error' );
    diag "Error: $hResult->{'Error'}->{'Message'}\n" if $hResult->{'Error'};

    ok( $hResult->{'Alias'} eq $Options{'Alias'}, 'catalog alias' );
    is( $hResult->{'created'}, 1, 'created?' );
}

# Update a Catalog and check if the update was successful
sub testUpdate {

    my $ahResults = $CatalogService->update( [$Catalog_update] )->result;
    is( scalar @$ahResults, 1, 'update result count' );

    my $hResult = $ahResults->[0];
    ok( !$hResult->{'Error'}, 'update: no error' );
    diag "Error: $hResult->{'Error'}->{'Message'}\n" if $hResult->{'Error'};

    ok( $hResult->{'Path'} eq $Options{'FullPath'}, 'catalog path' );
    is( $hResult->{'updated'}, 1, 'updated?' );
}

# Retrieve information about an Catalog. Check if the returned data are equal to
# the data of create or update call
sub testGetInfo {
    my ($alreadyUpdated) = @_;
    my $ext = $alreadyUpdated ? '_up' : '_in';

    my $ahResults = $CatalogService->getInfo( [$Options{'FullPath'}], ['Date'] )->result;
    is( scalar @$ahResults, 1, 'getInfo result count' );

    my $hResult = $ahResults->[0];
    ok( !$hResult->{'Error'}, 'getInfo: no error' );
    diag "Error: $hResult->{'Error'}->{'Message'}\n" if $hResult->{'Error'};

    ok( $hResult->{'ParentCatalog'} eq WEBSERVICE_SHOP_PATH.$Options{'Path'},             'parent catalog' );
    ok( $hResult->{'Path'}          eq WEBSERVICE_SHOP_PATH.$Options{'FullPath'},         'catalog path' );

    my $hName = hLocalizedString($hResult->{'Name'});
    ok( $hName->{'de'} eq $Options{"Name$ext"}{'de'},   'name (de)' );
    ok( $hName->{'en'} eq $Options{"Name$ext"}{'en'},   'name (en)' );

    my  $hAttributes = hAttributes($hResult->{'Attributes'});
    is( 0, cmpDateTime($hAttributes->{'Date'}, $Options{"Attr$ext"}{'Date'}), 'attribute value (Date)' );
}

sub deleteIfExists {
    my $ahResults = $CatalogService->exists( [$Options{'FullPath'}] )->result;
    die $ahResults->[0]->{'Error'}->{'Message'} if $ahResults->[0]->{'Error'};

    if ( $ahResults->[0]->{'exists'} ) {
        $ahResults = $CatalogService->delete( [$Options{'FullPath'}] )->result;
        die $ahResults->[0]->{'Error'}->{'Message'} if $ahResults->[0]->{'Error'};
    }
}

# Delete a Catalog and check if no error occured.
sub testDelete {

    my $ahResults = $CatalogService->delete( [$Options{'FullPath'}] )->result;
    is( scalar @$ahResults, 1, 'delete result count' );

    my $hResult = $ahResults->[0];
    ok( !$hResult->{'Error'}, 'delete: no error' );
    diag "Error: $hResult->{'Error'}->{'Message'}\n" if $hResult->{'Error'};

    ok( $hResult->{'Path'} eq $Options{'FullPath'}, 'catalog path' );
    is( $hResult->{'deleted'}, 1, 'deleted?' );
}

# Test if a Catalog exists or not
sub testExists {
    my ($exists) = @_;

    my $ahResults = $CatalogService->exists( [$Options{'FullPath'}] )->result;
    is( scalar @$ahResults, 1, 'exists result count' );

    my $hResult = $ahResults->[0];
    ok( !$hResult->{'Error'}, 'exists: no error' );
    diag "Error: $hResult->{'Error'}->{'Message'}\n" if $hResult->{'Error'};

    ok( $hResult->{'Path'} eq $Options{'FullPath'}, 'catalog path' );
    is( $hResult->{'exists'}, $exists, 'exists?' );
}

# run test suite
deleteIfExists();
testCreate();
testExists(1);
testGetInfo(0);
testUpdate();
testGetInfo(1);
testDelete();
testExists(0);