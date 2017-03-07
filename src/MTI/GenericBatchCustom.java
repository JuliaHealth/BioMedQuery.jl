/*
  ===========================================================================
  *
  *                            PUBLIC DOMAIN NOTICE
  *               National Center for Biotechnology Information
  *         Lister Hill National Center for Biomedical Communications
  *
  *  This software is a "United States Government Work" under the terms of the
  *  United States Copyright Act.  It was written as part of the authors' official
  *  duties as a United States Government contractor and thus cannot be
  *  copyrighted.  This software is freely available to the public for use. The
  *  National Library of Medicine and the U.S. Government have not placed any
  *  restriction on its use or reproduction.
  *
  *  Although all reasonable efforts have been taken to ensure the accuracy
  *  and reliability of the software and data, the NLM and the U.S.
  *  Government do not and cannot warrant the performance or results that
  *  may be obtained by using this software or data. The NLM and the U.S.
  *  Government disclaim all warranties, express or implied, including
  *  warranties of performance, merchantability or fitness for any particular
  *  purpose.
  *
  *  Please cite the authors in any work or product based on this material.
  *
  ===========================================================================
*/

/**
 * Example program for submitting a new Generic Batch with Validation job
 * request to the Scheduler to run. You will be prompted for your username and
 * password and if they are alright, the job is submitted to the Scheduler and
 * the results are returned in the String "results" below.
 *
 * This example shows how to setup a basic Generic Batch with Validation job
 * with a small file (sample.txt) with ASCII MEDLINE formatted citations as
 * input data. You must set the Email_Address variable and use the UpLoad_File
 * to specify the data to be processed.  This example also shows the user
 * setting the SilentEmail option which tells the Scheduler to NOT send email
 * upon completing the job.
 *
 * This example is set to run the MTI (Medical Text Indexer) program using
 * the -opt1L_DCMS and -E options. You can also setup any environment variables
 * that will be needed by the program by setting the Batch_Env field.
 * The "-E" option is required for all of the various SKR tools (MetaMap,
 * SemRep, and MTI), so please make sure to add the option to your command!
 *
 * @author	Jim Mork
 * @version	1.0, September 18, 2006
 **/


import java.io.*;
import java.util.List;
import java.util.ArrayList;
import gov.nih.nlm.nls.skr.*;

public class GenericBatchCustom
{
  static String defaultCommand = "MTI -default_MTI -detail -E";
  // static String defaultCommand = "MTI -MoD_PP -detail -E";

  /** print information about server options */
  public static void printHelp() {
    System.out.println("usage: GenericBatchCustom [options] inputFilename");
    System.out.println("  allowed options: ");
    System.out.println("    --email <address> : set email address. (required option)");
    System.out.println("    --command <name> : batch command: metamap, semrep, etc. (default: " +
		       defaultCommand + ")");
    System.out.println("    --note <notes> : batch notes ");
    System.out.println("    --silent : don't send email after job completes.");
    System.out.println("    --silent-errors : Silent on Errors");
    System.out.println("    --singleLineInput : Single Line Delimited Input");
    System.out.println("    --singleLinePMID : Single Line Delimited Input w/ID");
    System.out.println("    --priority : request a Run Priority Level: 0, 1, or 2");
  }

  /**
   * If supplied value string is null or empty then display usage
   * message and exit program.
   * @param value variable to be tested.
   * @param msg error message to precede usage message.
   */
  static void fatalMessageIfEmptyString(String value, String msg) {
    if (value != null) {
      if (value.length() > 0) {
	return;
      }
    }
    System.out.println(msg);
    printHelp();
    System.exit(1);
  }

  public static void main(String args[])
  {
    // NOTE: You MUST specify an email address because it is used for
    //       logging purposes.
    String emailAddress = null;
    String username = null;
    String password = null;
    String batchCommand = defaultCommand;
    String batchNotes = "SKR API Test";
    boolean silentEmail = false;
    boolean silentOnErrors = false;
    boolean singleLineDelimitedInput = false;
    boolean singleLineDelimitedInputWithId = false;
    int priority = -1;

      if (args.length < 1) {
	printHelp();
	System.exit(1);
      }
    StringBuffer inputBuf = new StringBuffer();
    List<String> options = new ArrayList<String>();

    int i = 0;
    while (i < args.length) {
      if (args[i].charAt(0) == '-') {
	if (args[i].equals("-h") || args[i].equals("--help") || args[i].equals("-?")) {
	  printHelp();
	  System.exit(0);
	} else if ( args[i].equals("--email-address") || args[i].equals("--email")) {
	  i++;
	  emailAddress = args[i];
    } else if ( args[i].equals("--username")) {
	  i++;
	  username = args[i];
    } else if ( args[i].equals("--password")) {
	  i++;
	  password = args[i];
	} else if ( args[i].equals("--command") || args[i].equals("--batch-command")) {
	  i++;
	  batchCommand = args[i];
	} else if ( args[i].equals("--note") || args[i].equals("--batch-note")) {
	  i++;
	  batchNotes = args[i];
	} else if ( args[i].equals("--silent") || args[i].equals("--silent-email")) {
	  silentEmail = true;
	} else if ( args[i].equals("--silent-errors") || args[i].equals("--silent-on-errors")) {
	  silentOnErrors = true;
	} else if ( args[i].equals("--singleLineInput") || args[i].equals("--singleLineDelimitedInput")) {
	   singleLineDelimitedInput = true;
	} else if ( args[i].equals("--singleLinePMID") ||
		    args[i].equals("--singleLineDelimitedInputWithPMID")) {
	   singleLineDelimitedInputWithId = true;
	} else if ( args[i].equals("--priority") ) {
	  i++;
	  try {
	    priority = Integer.parseInt(args[i]);
	    if ((priority < 0) || (priority > 2)) {
	      System.err.println("argument to --priority must be a integer between 0 and 2");
	      System.exit(0);
	    }
	  } catch (NumberFormatException e) {
	    System.err.println("argument to --priority must be a integer between 0 and 2");
	    System.exit(0);
	  }
	}
      } else {
	inputBuf.append(args[i]).append(" ");
      }
      i++;
    }
    // Instantiate the object for Generic Batch
    GenericObject myGenericObj = new GenericObject(username, password);
    fatalMessageIfEmptyString(emailAddress, "email address is required.");
    myGenericObj.setField("Email_Address", emailAddress);
    fatalMessageIfEmptyString(batchCommand, "command for batch processing is required.");

    System.out.println("Command:");
    System.out.println(batchCommand);

    myGenericObj.setField("Batch_Command", batchCommand);
    if (batchNotes != null) {
      myGenericObj.setField("BatchNotes", batchNotes);
    }
    myGenericObj.setField("SilentEmail", silentEmail);
    if (silentOnErrors) {
      myGenericObj.setField("ESilent", silentOnErrors);
    }
    if (singleLineDelimitedInput) {
      myGenericObj.setField("SingLine", singleLineDelimitedInput);
    }
    if (singleLineDelimitedInputWithId) {
      myGenericObj.setField("SingLinePMID", singleLineDelimitedInputWithId);
    }
    if (priority > 0) {
      myGenericObj.setField("RPriority", Integer.toString(priority));
    }

    if (inputBuf.length() > 0) {
      File inFile = new File(inputBuf.toString().trim());
      if (inFile.exists()) {
	myGenericObj.setFileField("UpLoad_File", inputBuf.toString().trim());
      }
    }
    // Submit the job request
    try
      {
	String results = myGenericObj.handleSubmission();
	System.out.print(results);

      } catch (RuntimeException ex) {
      System.err.println("");
      System.err.print("An ERROR has occurred while processing your");
      System.err.println(" request, please review any");
      System.err.print("lines beginning with \"Error:\" above and the");
      System.err.println(" trace below for indications of");
      System.err.println("what may have gone wrong.");
      System.err.println("");
      System.err.println("Trace:");
      ex.printStackTrace();
    } // catch
  } // main
} // class GenericBatchNew
