/* Program identity shared by every unit (CONV-01, CONV-02). */
#ifndef DPH_PROGRAM_H
#define DPH_PROGRAM_H

/* Canonical name used in every diagnostic, the help text, and the version line. */
#define DPH_PROGRAM_NAME "dp-hello"

/* Specification version printed by --version. */
#define DPH_PROGRAM_VERSION "1.0.0"

/* Exit statuses (SRS section 3.7, CONV-18). */
enum {
  DPHExitSuccess = 0,
  DPHExitFailure = 1, /* stdout unwritable (CONV-25 leaves the status unspecified) */
  DPHExitUsage = 2
};

#endif
