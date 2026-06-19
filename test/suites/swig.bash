# SUITE_swig_PROBE() { }

genswigcode() {
    outfile="$1"
    nlines=$2
    i=0;
    (
    echo "%module swigtest$2;"
    while [ $i -lt $nlines ]; do
        echo "int foo$nlines$i(int x);"
        echo "struct Bar$nlines$i { int y; };"
        i=`expr $i + 1`
    done
    ) >> "$outfile"
}

SUITE_swig_SETUP() {
    genswigcode testswig1.i 1
}

SUITE_swig() {
    # -------------------------------------------------------------------------
    TEST "Swig testsuite"

    return # TODO

    expect_stat direct_cache_hit 0
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 0

    TEST "BASIC"
    $CCACHE_COMPILE -java testswig1.i
    expect_stat direct_cache_hit 0
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 1
    expect_stat files_in_cache 6

    TEST "BASIC2"
    $CCACHE_COMPILE -java testswig1.i
    expect_stat direct_cache_hit 1
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 1

    TEST "output"
    $CCACHE_COMPILE -java testswig1.i -o foo_wrap.c
    expect_stat direct_cache_hit 1
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 2

    TEST "bad"
    $CCACHE_COMPILE -java testswig1.i -I
    expect_stat bad_compiler_arguments 1

    TEST "stdout"
    $CCACHE_COMPILE -v -java testswig1.i
    expect_stat compiler_produced_stdout 1

    TEST "non-regular"
    mkdir testd
    $CCACHE_COMPILE -o testd -java testswig1.i
    expect_stat 'output_to_a_non-regular_file' 1

    TEST "CCACHE_DISABLE"
    CCACHE_DISABLE=1 $CCACHE_COMPILE -java testswig1.i
    expect_stat direct_cache_hit 1
    expect_stat preprocessed_cache_hit 0
    $CCACHE_COMPILE -java testswig1.i
    expect_stat direct_cache_hit 2
    expect_stat preprocessed_cache_hit 0

    TEST "CCACHE_CPP2"
    CCACHE_CPP2=1 $CCACHE_COMPILE -java -O -O testswig1.i
    expect_stat direct_cache_hit 2
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 3

    CCACHE_CPP2=1 $CCACHE_COMPILE -java -O -O testswig1.i
    expect_stat direct_cache_hit 3
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 3

    TEST "CCACHE_NOSTATS"
    CCACHE_NOSTATS=1 $CCACHE_COMPILE -java -O -O testswig1.i
    expect_stat direct_cache_hit 3
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 3

    TEST "CCACHE_RECACHE"
    CCACHE_RECACHE=1 $CCACHE_COMPILE -java -O -O testswig1.i
    expect_stat direct_cache_hit 3
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 4

    # strictly speaking should be 3x6=18 instead of 4x6=24 - RECACHE causes a double counting!
    expect_stat files_in_cache 24
    $CCACHE -c
    expect_stat files_in_cache 18

    TEST "CCACHE_HASHDIR"
    CCACHE_HASHDIR=1 $CCACHE_COMPILE -java -O -O testswig1.i
    expect_stat direct_cache_hit 3
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 5

    CCACHE_HASHDIR=1 $CCACHE_COMPILE -java -O -O testswig1.i
    expect_stat direct_cache_hit 4
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 5

    expect_stat files_in_cache 24

    TEST "cpp call"
    $CCACHE_COMPILE -java -E testswig1.i > testswig1-preproc.i
    expect_stat direct_cache_hit 4
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 5

    TEST "direct .i compile"
    $CCACHE_COMPILE -java testswig1.i
    expect_stat direct_cache_hit 5
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 5

    # No cache hit due to different input file name, -nopreprocess should not be given twice to SWIG
    $CCACHE_COMPILE -java -nopreprocess testswig1-preproc.i
    expect_stat direct_cache_hit 5
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 6

    $CCACHE_COMPILE -java -nopreprocess testswig1-preproc.i
    expect_stat direct_cache_hit 6
    expect_stat preprocessed_cache_hit 0
    expect_stat cache_miss 6

    rm testswig1.i 1 testswig1-preproc.i
}
