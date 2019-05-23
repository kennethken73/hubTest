// <<< remember to make genDepAll or genTestDeps >>>
#define BOOST_TEST_MODULE <<<RENAME>>>
#define BOOST_TEST_MAIN

#include <boost/test/included/unit_test.hpp>
#include <boost/test/output_test_stream.hpp>
#include <fstream>
#include <iostream>
#include <sstream>

using boost::test_tools::output_test_stream;
using std::cout;

BOOST_AUTO_TEST_SUITE(main_suite)

// <<<string_test_name>>>{{{
// TODO make this a snip: 'bst - boost string test'
BOOST_AUTO_TEST_CASE(/* <<<string_test_name>>>*/) {
  // setup

  // ####### string-testing: ########
  // redirect cout -> oss
  std::ostringstream oss;
  std::streambuf* p_cout_streambuf = std::cout.rdbuf();
  std::cout.rdbuf(oss.rdbuf());

  // put pattern_file as 1st arg. to boost_string_test_obj
  // (don't set flush flag unless its really needed)
  output_test_stream output(" */pattern_file*/ ", true);
  dataSet.printData();  // -> oss
  output << oss.str();  // put string-to-test to boost_string_test_obj

  BOOST_TEST(output.match_pattern(), true);

  // reset cout and cleanup
  std::cout.rdbuf(p_cout_streambuf);
  // ##################################
  //
}
/*}}}*/

// ultisnip -> btc
//   to insert new test-case

BOOST_AUTO_TEST_SUITE_END()
