/*
A KBase module: GenomeComparison
This sample module contains one small method - filter_contigs.
*/

module GenomeComparison {
    typedef structure {
		list<string> genome_refs;
		string genomeset_ref;
		string workspace;
		string output_id;
    } BuildPangenomeParams;

    typedef structure {
	string report_name;
	string report_ref;
	string pg_ref;
    } BuildPangenomeResult;

    funcdef build_pangenome(BuildPangenomeParams input) returns (BuildPangenomeResult) authentication required;

    typedef structure {
	string pangenome_ref;
	string protcomp_ref;
	string output_id;
	string workspace;
    } CompareGenomesParams;

    typedef structure {
	string report_name;
	string report_ref;
	string cg_ref;
    } CompareGenomesResult;

    /*
    Compares the specified genomes and computes unique features and core features
    */
    funcdef compare_genomes(CompareGenomesParams params) returns (CompareGenomesResult) authentication optional;
};