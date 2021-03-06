      SUBROUTINE G7LIT(D, G, IV, LIV, LV, P, PS, V, X, Y)
C
C  ***  CARRY OUT NL2SOL-LIKE ITERATIONS FOR GENERALIZED LINEAR   ***
C  ***  REGRESSION PROBLEMS (AND OTHERS OF SIMILAR STRUCTURE)     ***
C
C  ***  PARAMETER DECLARATIONS  ***
C
      INTEGER LIV, LV, P, PS
      INTEGER IV(LIV)
      REAL D(P), G(P), V(LV), X(P), Y(P)
C
C--------------------------  PARAMETER USAGE  --------------------------
C
C D.... SCALE VECTOR.
C IV... INTEGER VALUE ARRAY.
C LIV.. LENGTH OF IV.  MUST BE AT LEAST 82.
C LH... LENGTH OF H = P*(P+1)/2.
C LV... LENGTH OF V.  MUST BE AT LEAST P*(3*P + 19)/2 + 7.
C G.... GRADIENT AT X (WHEN IV(1) = 2).
C P.... NUMBER OF PARAMETERS (COMPONENTS IN X).
C PS... NUMBER OF NONZERO ROWS AND COLUMNS IN S.
C V.... FLOATING-POINT VALUE ARRAY.
C X.... PARAMETER VECTOR.
C Y.... PART OF YIELD VECTOR (WHEN IV(1)= 2, SCRATCH OTHERWISE).
C
C  ***  DISCUSSION  ***
C
C        G7LIT PERFORMS NL2SOL-LIKE ITERATIONS FOR A VARIETY OF
C     REGRESSION PROBLEMS THAT ARE SIMILAR TO NONLINEAR LEAST-SQUARES
C     IN THAT THE HESSIAN IS THE SUM OF TWO TERMS, A READILY-COMPUTED
C     FIRST-ORDER TERM AND A SECOND-ORDER TERM.  THE CALLER SUPPLIES
C     THE FIRST-ORDER TERM OF THE HESSIAN IN HC (LOWER TRIANGLE, STORED
C     COMPACTLY BY ROWS IN V, STARTING AT IV(HC)), AND G7LIT BUILDS AN
C     APPROXIMATION, S, TO THE SECOND-ORDER TERM.  THE CALLER ALSO
C     PROVIDES THE FUNCTION VALUE, GRADIENT, AND PART OF THE YIELD
C     VECTOR USED IN UPDATING S.  G7LIT DECIDES DYNAMICALLY WHETHER OR
C     NOT TO USE S WHEN CHOOSING THE NEXT STEP TO TRY...  THE HESSIAN
C     APPROXIMATION USED IS EITHER HC ALONE (GAUSS-NEWTON MODEL) OR
C     HC + S (AUGMENTED MODEL).
C
C        IF PS .LT. P, THEN ROWS AND COLUMNS PS+1...P OF S ARE KEPT
C     CONSTANT.  THEY WILL BE ZERO UNLESS THE CALLER SETS IV(INITS) TO
C     1 OR 2 AND SUPPLIES NONZERO VALUES FOR THEM, OR THE CALLER SETS
C     IV(INITS) TO 3 OR 4 AND THE FINITE-DIFFERENCE INITIAL S THEN
C     COMPUTED HAS NONZERO VALUES IN THESE ROWS.
C
C        IF IV(INITS) IS 3 OR 4, THEN THE INITIAL S IS COMPUTED BY
C     FINITE DIFFERENCES.  3 MEANS USE FUNCTION DIFFERENCES, 4 MEANS
C     USE GRADIENT DIFFERENCES.  FINITE DIFFERENCING IS DONE THE SAME
C     WAY AS IN COMPUTING A COVARIANCE MATRIX (WITH IV(COVREQ) = -1, -2,
C     1, OR 2).
C
C        FOR UPDATING S, G7LIT ASSUMES THAT THE GRADIENT HAS THE FORM
C     OF A SUM OVER I OF RHO(I,X)*GRAD(R(I,X)), WHERE GRAD DENOTES THE
C     GRADIENT WITH RESPECT TO X.  THE TRUE SECOND-ORDER TERM THEN IS
C     THE SUM OVER I OF RHO(I,X)*HESSIAN(R(I,X)).  IF X = X0 + STEP,
C     THEN WE WISH TO UPDATE S SO THAT S*STEP IS THE SUM OVER I OF
C     RHO(I,X)*(GRAD(R(I,X)) - GRAD(R(I,X0))).  THE CALLER MUST SUPPLY
C     PART OF THIS IN Y, NAMELY THE SUM OVER I OF
C     RHO(I,X)*GRAD(R(I,X0)), WHEN CALLING G7LIT WITH IV(1) = 2 AND
C     IV(MODE) = 0 (WHERE MODE = 38).  G THEN CONTANS THE OTHER PART,
C     SO THAT THE DESIRED YIELD VECTOR IS G - Y.  IF PS .LT. P, THEN
C     THE ABOVE DISCUSSION APPLIES ONLY TO THE FIRST PS COMPONENTS OF
C     GRAD(R(I,X)), STEP, AND Y.
C
C        PARAMETERS IV, P, V, AND X ARE THE SAME AS THE CORRESPONDING
C     ONES TO NL2SOL (WHICH SEE), EXCEPT THAT V CAN BE SHORTER
C     (SINCE THE PART OF V THAT NL2SOL USES FOR STORING D, J, AND R IS
C     NOT NEEDED).  MOREOVER, COMPARED WITH NL2SOL, IV(1) MAY HAVE THE
C     TWO ADDITIONAL OUTPUT VALUES 1 AND 2, WHICH ARE EXPLAINED BELOW,
C     AS IS THE USE OF IV(TOOBIG) AND IV(NFGCAL).  THE VALUES IV(D),
C     IV(J), AND IV(R), WHICH ARE OUTPUT VALUES FROM NL2SOL (AND
C     NL2SNO), ARE NOT REFERENCED BY G7LIT OR THE SUBROUTINES IT CALLS.
C
C        WHEN G7LIT IS FIRST CALLED, I.E., WHEN G7LIT IS CALLED WITH
C     IV(1) = 0 OR 12, V(F), G, AND HC NEED NOT BE INITIALIZED.  TO
C     OBTAIN THESE STARTING VALUES, G7LIT RETURNS FIRST WITH IV(1) = 1,
C     THEN WITH IV(1) = 2, WITH IV(MODE) = -1 IN BOTH CASES.  ON
C     SUBSEQUENT RETURNS WITH IV(1) = 2, IV(MODE) = 0 IMPLIES THAT
C     Y MUST ALSO BE SUPPLIED.  (NOTE THAT Y IS USED FOR SCRATCH -- ITS
C     INPUT CONTENTS ARE LOST.  BY CONTRAST, HC IS NEVER CHANGED.)
C     ONCE CONVERGENCE HAS BEEN OBTAINED, IV(RDREQ) AND IV(COVREQ) MAY
C     IMPLY THAT A FINITE-DIFFERENCE HESSIAN SHOULD BE COMPUTED FOR USE
C     IN COMPUTING A COVARIANCE MATRIX.  IN THIS CASE G7LIT WILL MAKE A
C     NUMBER OF RETURNS WITH IV(1) = 1 OR 2 AND IV(MODE) POSITIVE.
C     WHEN IV(MODE) IS POSITIVE, Y SHOULD NOT BE CHANGED.
C
C IV(1) = 1 MEANS THE CALLER SHOULD SET V(F) (I.E., V(10)) TO F(X), THE
C             FUNCTION VALUE AT X, AND CALL G7LIT AGAIN, HAVING CHANGED
C             NONE OF THE OTHER PARAMETERS.  AN EXCEPTION OCCURS IF F(X)
C             CANNOT BE EVALUATED (E.G. IF OVERFLOW WOULD OCCUR), WHICH
C             MAY HAPPEN BECAUSE OF AN OVERSIZED STEP.  IN THIS CASE
C             THE CALLER SHOULD SET IV(TOOBIG) = IV(2) TO 1, WHICH WILL
C             CAUSE G7LIT TO IGNORE V(F) AND TRY A SMALLER STEP.  NOTE
C             THAT THE CURRENT FUNCTION EVALUATION COUNT IS AVAILABLE
C             IN IV(NFCALL) = IV(6).  THIS MAY BE USED TO IDENTIFY
C             WHICH COPY OF SAVED INFORMATION SHOULD BE USED IN COM-
C             PUTING G, HC, AND Y THE NEXT TIME G7LIT RETURNS WITH
C             IV(1) = 2.  SEE MLPIT FOR AN EXAMPLE OF THIS.
C IV(1) = 2 MEANS THE CALLER SHOULD SET G TO G(X), THE GRADIENT OF F AT
C             X.  THE CALLER SHOULD ALSO SET HC TO THE GAUSS-NEWTON
C             HESSIAN AT X.  IF IV(MODE) = 0, THEN THE CALLER SHOULD
C             ALSO COMPUTE THE PART OF THE YIELD VECTOR DESCRIBED ABOVE.
C             THE CALLER SHOULD THEN CALL G7LIT AGAIN (WITH IV(1) = 2).
C             THE CALLER MAY ALSO CHANGE D AT THIS TIME, BUT SHOULD NOT
C             CHANGE X.  NOTE THAT IV(NFGCAL) = IV(7) CONTAINS THE
C             VALUE THAT IV(NFCALL) HAD DURING THE RETURN WITH
C             IV(1) = 1 IN WHICH X HAD THE SAME VALUE AS IT NOW HAS.
C             IV(NFGCAL) IS EITHER IV(NFCALL) OR IV(NFCALL) - 1.  MLPIT
C             IS AN EXAMPLE WHERE THIS INFORMATION IS USED.  IF G OR HC
C             CANNOT BE EVALUATED AT X, THEN THE CALLER MAY SET
C             IV(TOOBIG) TO 1, IN WHICH CASE G7LIT WILL RETURN WITH
C             IV(1) = 15.
C
C  ***  GENERAL  ***
C
C     CODED BY DAVID M. GAY.
C     THIS SUBROUTINE WAS WRITTEN IN CONNECTION WITH RESEARCH
C     SUPPORTED IN PART BY D.O.E. GRANT EX-76-A-01-2295 TO MIT/CCREMS.
C
C        (SEE NL2SOL FOR REFERENCES.)
C
C+++++++++++++++++++++++++++  DECLARATIONS  ++++++++++++++++++++++++++++
C
C  ***  LOCAL VARIABLES  ***
C
      INTEGER DUMMY, DIG1, G01, H1, HC1, I, IPIV1, J, K, L, LMAT1,
     1        LSTGST, PP1O2, QTR1, RMAT1, RSTRST, STEP1, STPMOD, S1,
     2        TEMP1, TEMP2, W1, X01
      REAL E, STTSST, T, T1
C
C     ***  CONSTANTS  ***
C
      REAL HALF, NEGONE, ONE, ONEP2, ZERO
C
C  ***  EXTERNAL FUNCTIONS AND SUBROUTINES  ***
C
      LOGICAL STOPX
      REAL  D7TPR,  L7SVX,  L7SVN,  RLDST,  R7MDC,  V2NRM
      EXTERNAL A7SST,  D7TPR, F7HES, G7QTS, ITSUM,  L7MST, L7SRT,
     1          L7SQR,  L7SVX,  L7SVN,  L7TVM, L7VML, PARCK,  RLDST,
     2          R7MDC,  S7LUP,  S7LVM, STOPX, V2AXY, V7CPY,  V7SCP,
     3          V2NRM
C
C A7SST.... ASSESSES CANDIDATE STEP.
C  D7TPR... RETURNS INNER PRODUCT OF TWO VECTORS.
C F7HES.... COMPUTE FINITE-DIFFERENCE HESSIAN (FOR COVARIANCE).
C G7QTS.... COMPUTES GOLDFELD-QUANDT-TROTTER STEP (AUGMENTED MODEL).
C ITSUM.... PRINTS ITERATION SUMMARY AND INFO ON INITIAL AND FINAL X.
C  L7MST... COMPUTES LEVENBERG-MARQUARDT STEP (GAUSS-NEWTON MODEL).
C L7SRT.... COMPUTES CHOLESKY FACTOR OF (LOWER TRIANG. OF) SYM. MATRIX.
C  L7SQR... COMPUTES L * L**T FROM LOWER TRIANGULAR MATRIX L.
C  L7TVM... COMPUTES L**T * V, V = VECTOR, L = LOWER TRIANGULAR MATRIX.
C  L7SVX... ESTIMATES LARGEST SING. VALUE OF LOWER TRIANG. MATRIX.
C  L7SVN... ESTIMATES SMALLEST SING. VALUE OF LOWER TRIANG. MATRIX.
C L7VML.... COMPUTES L * V, V = VECTOR, L = LOWER TRIANGULAR MATRIX.
C PARCK.... CHECK VALIDITY OF IV AND V INPUT COMPONENTS.
C  RLDST... COMPUTES V(RELDX) = RELATIVE STEP SIZE.
C  R7MDC... RETURNS MACHINE-DEPENDENT CONSTANTS.
C  S7LUP... PERFORMS QUASI-NEWTON UPDATE ON COMPACTLY STORED LOWER TRI-
C             ANGLE OF A SYMMETRIC MATRIX.
C STOPX.... RETURNS .TRUE. IF THE BREAK KEY HAS BEEN PRESSED.
C V2AXY.... COMPUTES SCALAR TIMES ONE VECTOR PLUS ANOTHER.
C V7CPY.... COPIES ONE VECTOR TO ANOTHER.
C  V7SCP... SETS ALL ELEMENTS OF A VECTOR TO A SCALAR.
C  V2NRM... RETURNS THE 2-NORM OF A VECTOR.
C
C  ***  SUBSCRIPTS FOR IV AND V  ***
C
      INTEGER CNVCOD, COSMIN, COVMAT, COVREQ, DGNORM, DIG, DSTNRM, F,
     1        FDH, FDIF, FUZZ, F0, GTSTEP, H, HC, IERR, INCFAC, INITS,
     2        IPIVOT, IRC, KAGQT, KALM, LMAT, LMAX0, LMAXS, MODE, MODEL,
     3        MXFCAL, MXITER, NEXTV, NFCALL, NFGCAL, NFCOV, NGCOV,
     4        NGCALL, NITER, NVSAVE, PHMXFC, PREDUC, QTR, RADFAC,
     5        RADINC, RADIUS, RAD0, RCOND, RDREQ, REGD, RELDX, RESTOR,
     6        RMAT, S, SIZE, STEP, STGLIM, STLSTG, STPPAR, SUSED,
     7        SWITCH, TOOBIG, TUNER4, TUNER5, VNEED, VSAVE, W, WSCALE,
     8        XIRC, X0
C
C  ***  IV SUBSCRIPT VALUES  ***
C
C/6
C     DATA CNVCOD/55/, COVMAT/26/, COVREQ/15/, DIG/37/, FDH/74/, H/56/,
C    1     HC/71/, IERR/75/, INITS/25/, IPIVOT/76/, IRC/29/, KAGQT/33/,
C    2     KALM/34/, LMAT/42/, MODE/35/, MODEL/5/, MXFCAL/17/,
C    3     MXITER/18/, NEXTV/47/, NFCALL/6/, NFGCAL/7/, NFCOV/52/,
C    4     NGCOV/53/, NGCALL/30/, NITER/31/, QTR/77/, RADINC/8/,
C    5     RDREQ/57/, REGD/67/, RESTOR/9/, RMAT/78/, S/62/, STEP/40/,
C    6     STGLIM/11/, STLSTG/41/, SUSED/64/, SWITCH/12/, TOOBIG/2/,
C    7     VNEED/4/, VSAVE/60/, W/65/, XIRC/13/, X0/43/
C/7
      PARAMETER (CNVCOD=55, COVMAT=26, COVREQ=15, DIG=37, FDH=74, H=56,
     1           HC=71, IERR=75, INITS=25, IPIVOT=76, IRC=29, KAGQT=33,
     2           KALM=34, LMAT=42, MODE=35, MODEL=5, MXFCAL=17,
     3           MXITER=18, NEXTV=47, NFCALL=6, NFGCAL=7, NFCOV=52,
     4           NGCOV=53, NGCALL=30, NITER=31, QTR=77, RADINC=8,
     5           RDREQ=57, REGD=67, RESTOR=9, RMAT=78, S=62, STEP=40,
     6           STGLIM=11, STLSTG=41, SUSED=64, SWITCH=12, TOOBIG=2,
     7           VNEED=4, VSAVE=60, W=65, XIRC=13, X0=43)
C/
C
C  ***  V SUBSCRIPT VALUES  ***
C
C/6
C     DATA COSMIN/47/, DGNORM/1/, DSTNRM/2/, F/10/, FDIF/11/, FUZZ/45/,
C    1     F0/13/, GTSTEP/4/, INCFAC/23/, LMAX0/35/, LMAXS/36/,
C    2     NVSAVE/9/, PHMXFC/21/, PREDUC/7/, RADFAC/16/, RADIUS/8/,
C    3     RAD0/9/, RCOND/53/, RELDX/17/, SIZE/55/, STPPAR/5/,
C    4     TUNER4/29/, TUNER5/30/, WSCALE/56/
C/7
      PARAMETER (COSMIN=47, DGNORM=1, DSTNRM=2, F=10, FDIF=11, FUZZ=45,
     1           F0=13, GTSTEP=4, INCFAC=23, LMAX0=35, LMAXS=36,
     2           NVSAVE=9, PHMXFC=21, PREDUC=7, RADFAC=16, RADIUS=8,
     3           RAD0=9, RCOND=53, RELDX=17, SIZE=55, STPPAR=5,
     4           TUNER4=29, TUNER5=30, WSCALE=56)
C/
C
C
C/6
C     DATA HALF/0.5E+0/, NEGONE/-1.E+0/, ONE/1.E+0/, ONEP2/1.2E+0/,
C    1     ZERO/0.E+0/
C/7
      PARAMETER (HALF=0.5E+0, NEGONE=-1.E+0, ONE=1.E+0, ONEP2=1.2E+0,
     1           ZERO=0.E+0)
C/
C
C+++++++++++++++++++++++++++++++  BODY  ++++++++++++++++++++++++++++++++
C
      I = IV(1)
      IF (I .EQ. 1) GO TO 40
      IF (I .EQ. 2) GO TO 50
C
      IF (I .EQ. 12 .OR. I .EQ. 13)
     1     IV(VNEED) = IV(VNEED) + P*(3*P + 19)/2 + 7
      CALL PARCK(1, D, IV, LIV, LV, P, V)
      I = IV(1) - 2
      IF (I .GT. 12) GO TO 999
      GO TO (290, 290, 290, 290, 290, 290, 170, 120, 170, 10, 10, 20), I
C
C  ***  STORAGE ALLOCATION  ***
C
 10   PP1O2 = P * (P + 1) / 2
      IV(S) = IV(LMAT) + PP1O2
      IV(X0) = IV(S) + PP1O2
      IV(STEP) = IV(X0) + P
      IV(STLSTG) = IV(STEP) + P
      IV(DIG) = IV(STLSTG) + P
      IV(W) = IV(DIG) + P
      IV(H) = IV(W) + 4*P + 7
      IV(NEXTV) = IV(H) + PP1O2
      IF (IV(1) .NE. 13) GO TO 20
         IV(1) = 14
         GO TO 999
C
C  ***  INITIALIZATION  ***
C
 20   IV(NITER) = 0
      IV(NFCALL) = 1
      IV(NGCALL) = 1
      IV(NFGCAL) = 1
      IV(MODE) = -1
      IV(STGLIM) = 2
      IV(TOOBIG) = 0
      IV(CNVCOD) = 0
      IV(COVMAT) = 0
      IV(NFCOV) = 0
      IV(NGCOV) = 0
      IV(RADINC) = 0
      IV(RESTOR) = 0
      IV(FDH) = 0
      V(RAD0) = ZERO
      V(STPPAR) = ZERO
      V(RADIUS) = V(LMAX0) / (ONE + V(PHMXFC))
C
C  ***  SET INITIAL MODEL AND S MATRIX  ***
C
      IV(MODEL) = 1
      IF (IV(S) .LT. 0) GO TO 999
      IF (IV(INITS) .GT. 1) IV(MODEL) = 2
      S1 = IV(S)
      IF (IV(INITS) .EQ. 0 .OR. IV(INITS) .GT. 2)
     1   CALL  V7SCP(P*(P+1)/2, V(S1), ZERO)
      IV(1) = 1
      J = IV(IPIVOT)
      IF (J .LE. 0) GO TO 999
      DO 30 I = 1, P
         IV(J) = I
         J = J + 1
 30      CONTINUE
      GO TO 999
C
C  ***  NEW FUNCTION VALUE  ***
C
 40   IF (IV(MODE) .EQ. 0) GO TO 290
      IF (IV(MODE) .GT. 0) GO TO 520
C
      IV(1) = 2
      IF (IV(TOOBIG) .EQ. 0) GO TO 999
         IV(1) = 63
         GO TO 999
C
C  ***  NEW GRADIENT  ***
C
 50   IV(KALM) = -1
      IV(KAGQT) = -1
      IV(FDH) = 0
      IF (IV(MODE) .GT. 0) GO TO 520
C
C  ***  MAKE SURE GRADIENT COULD BE COMPUTED  ***
C
      IF (IV(TOOBIG) .EQ. 0) GO TO 60
         IV(1) = 65
         GO TO 999
 60   IF (IV(HC) .LE. 0 .AND. IV(RMAT) .LE. 0) GO TO 610
C
C  ***  COMPUTE  D**-1 * GRADIENT  ***
C
      DIG1 = IV(DIG)
      K = DIG1
      DO 70 I = 1, P
         V(K) = G(I) / D(I)
         K = K + 1
 70      CONTINUE
      V(DGNORM) =  V2NRM(P, V(DIG1))
C
      IF (IV(CNVCOD) .NE. 0) GO TO 510
      IF (IV(MODE) .EQ. 0) GO TO 440
      IV(MODE) = 0
      V(F0) = V(F)
      IF (IV(INITS) .LE. 2) GO TO 100
C
C  ***  ARRANGE FOR FINITE-DIFFERENCE INITIAL S  ***
C
      IV(XIRC) = IV(COVREQ)
      IV(COVREQ) = -1
      IF (IV(INITS) .GT. 3) IV(COVREQ) = 1
      IV(CNVCOD) = 70
      GO TO 530
C
C  ***  COME TO NEXT STMT AFTER COMPUTING F.D. HESSIAN FOR INIT. S  ***
C
 80   IV(CNVCOD) = 0
      IV(MODE) = 0
      IV(NFCOV) = 0
      IV(NGCOV) = 0
      IV(COVREQ) = IV(XIRC)
      S1 = IV(S)
      PP1O2 = PS * (PS + 1) / 2
      HC1 = IV(HC)
      IF (HC1 .LE. 0) GO TO 90
         CALL V2AXY(PP1O2, V(S1), NEGONE, V(HC1), V(H1))
         GO TO 100
 90   RMAT1 = IV(RMAT)
      CALL  L7SQR(PS, V(S1), V(RMAT1))
      CALL V2AXY(PP1O2, V(S1), NEGONE, V(S1), V(H1))
 100  IV(1) = 2
C
C
C-----------------------------  MAIN LOOP  -----------------------------
C
C
C  ***  PRINT ITERATION SUMMARY, CHECK ITERATION LIMIT  ***
C
 110  CALL ITSUM(D, G, IV, LIV, LV, P, V, X)
 120  K = IV(NITER)
      IF (K .LT. IV(MXITER)) GO TO 130
         IV(1) = 10
         GO TO 999
 130  IV(NITER) = K + 1
C
C  ***  UPDATE RADIUS  ***
C
      IF (K .EQ. 0) GO TO 150
      STEP1 = IV(STEP)
      DO 140 I = 1, P
         V(STEP1) = D(I) * V(STEP1)
         STEP1 = STEP1 + 1
 140     CONTINUE
      STEP1 = IV(STEP)
      T = V(RADFAC) *  V2NRM(P, V(STEP1))
      IF (V(RADFAC) .LT. ONE .OR. T .GT. V(RADIUS)) V(RADIUS) = T
C
C  ***  INITIALIZE FOR START OF NEXT ITERATION  ***
C
 150  X01 = IV(X0)
      V(F0) = V(F)
      IV(IRC) = 4
      IV(H) = -IABS(IV(H))
      IV(SUSED) = IV(MODEL)
C
C     ***  COPY X TO X0  ***
C
      CALL V7CPY(P, V(X01), X)
C
C  ***  CHECK STOPX AND FUNCTION EVALUATION LIMIT  ***
C
 160  IF (.NOT. STOPX(DUMMY)) GO TO 180
         IV(1) = 11
         GO TO 190
C
C     ***  COME HERE WHEN RESTARTING AFTER FUNC. EVAL. LIMIT OR STOPX.
C
 170  IF (V(F) .GE. V(F0)) GO TO 180
         V(RADFAC) = ONE
         K = IV(NITER)
         GO TO 130
C
 180  IF (IV(NFCALL) .LT. IV(MXFCAL) + IV(NFCOV)) GO TO 200
         IV(1) = 9
 190     IF (V(F) .GE. V(F0)) GO TO 999
C
C        ***  IN CASE OF STOPX OR FUNCTION EVALUATION LIMIT WITH
C        ***  IMPROVED V(F), EVALUATE THE GRADIENT AT X.
C
              IV(CNVCOD) = IV(1)
              GO TO 430
C
C. . . . . . . . . . . . .  COMPUTE CANDIDATE STEP  . . . . . . . . . .
C
 200  STEP1 = IV(STEP)
      W1 = IV(W)
      H1 = IV(H)
      T1 = ONE
      IF (IV(MODEL) .EQ. 2) GO TO 210
         T1 = ZERO
C
C        ***  COMPUTE LEVENBERG-MARQUARDT STEP IF POSSIBLE...
C
         RMAT1 = IV(RMAT)
         IF (RMAT1 .LE. 0) GO TO 210
         QTR1 = IV(QTR)
         IF (QTR1 .LE. 0) GO TO 210
         IPIV1 = IV(IPIVOT)
         CALL  L7MST(D, G, IV(IERR), IV(IPIV1), IV(KALM), P, V(QTR1),
     1               V(RMAT1), V(STEP1), V, V(W1))
C        *** H IS STORED IN THE END OF W AND HAS JUST BEEN OVERWRITTEN,
C        *** SO WE MARK IT INVALID...
         IV(H) = -IABS(H1)
C        *** EVEN IF H WERE STORED ELSEWHERE, IT WOULD BE NECESSARY TO
C        *** MARK INVALID THE INFORMATION G7QTS MAY HAVE STORED IN V...
         IV(KAGQT) = -1
         GO TO 260
C
 210  IF (H1 .GT. 0) GO TO 250
C
C     ***  SET H TO  D**-1 * (HC + T1*S) * D**-1.  ***
C
         H1 = -H1
         IV(H) = H1
         IV(FDH) = 0
         J = IV(HC)
         IF (J .GT. 0) GO TO 220
            J = H1
            RMAT1 = IV(RMAT)
            CALL  L7SQR(P, V(H1), V(RMAT1))
 220     S1 = IV(S)
         DO 240 I = 1, P
              T = ONE / D(I)
              DO 230 K = 1, I
                   V(H1) = T * (V(J) + T1*V(S1)) / D(K)
                   J = J + 1
                   H1 = H1 + 1
                   S1 = S1 + 1
 230               CONTINUE
 240          CONTINUE
         H1 = IV(H)
         IV(KAGQT) = -1
C
C  ***  COMPUTE ACTUAL GOLDFELD-QUANDT-TROTTER STEP  ***
C
 250  DIG1 = IV(DIG)
      LMAT1 = IV(LMAT)
      CALL G7QTS(D, V(DIG1), V(H1), IV(KAGQT), V(LMAT1), P, V(STEP1),
     1            V, V(W1))
      IF (IV(KALM) .GT. 0) IV(KALM) = 0
C
 260  IF (IV(IRC) .NE. 6) GO TO 270
         IF (IV(RESTOR) .NE. 2) GO TO 290
         RSTRST = 2
         GO TO 300
C
C  ***  CHECK WHETHER EVALUATING F(X0 + STEP) LOOKS WORTHWHILE  ***
C
 270  IV(TOOBIG) = 0
      IF (V(DSTNRM) .LE. ZERO) GO TO 290
      IF (IV(IRC) .NE. 5) GO TO 280
      IF (V(RADFAC) .LE. ONE) GO TO 280
      IF (V(PREDUC) .GT. ONEP2 * V(FDIF)) GO TO 280
         STEP1 = IV(STEP)
         X01 = IV(X0)
         CALL V2AXY(P, V(STEP1), NEGONE, V(X01), X)
         IF (IV(RESTOR) .NE. 2) GO TO 290
         RSTRST = 0
         GO TO 300
C
C  ***  COMPUTE F(X0 + STEP)  ***
C
 280  X01 = IV(X0)
      STEP1 = IV(STEP)
      CALL V2AXY(P, X, ONE, V(STEP1), V(X01))
      IV(NFCALL) = IV(NFCALL) + 1
      IV(1) = 1
      GO TO 999
C
C. . . . . . . . . . . . .  ASSESS CANDIDATE STEP  . . . . . . . . . . .
C
 290  RSTRST = 3
 300  X01 = IV(X0)
      V(RELDX) =  RLDST(P, D, X, V(X01))
      CALL A7SST(IV, LIV, LV, V)
      STEP1 = IV(STEP)
      LSTGST = IV(STLSTG)
      I = IV(RESTOR) + 1
      GO TO (340, 310, 320, 330), I
 310  CALL V7CPY(P, X, V(X01))
      GO TO 340
 320   CALL V7CPY(P, V(LSTGST), V(STEP1))
       GO TO 340
 330     CALL V7CPY(P, V(STEP1), V(LSTGST))
         CALL V2AXY(P, X, ONE, V(STEP1), V(X01))
         V(RELDX) =  RLDST(P, D, X, V(X01))
         IV(RESTOR) = RSTRST
C
C  ***  IF NECESSARY, SWITCH MODELS  ***
C
 340  IF (IV(SWITCH) .EQ. 0) GO TO 350
         IV(H) = -IABS(IV(H))
         IV(SUSED) = IV(SUSED) + 2
         L = IV(VSAVE)
         CALL V7CPY(NVSAVE, V, V(L))
 350  L = IV(IRC) - 4
      STPMOD = IV(MODEL)
      IF (L .GT. 0) GO TO (370,380,390,390,390,390,390,390,500,440), L
C
C  ***  DECIDE WHETHER TO CHANGE MODELS  ***
C
      E = V(PREDUC) - V(FDIF)
      S1 = IV(S)
      CALL  S7LVM(PS, Y, V(S1), V(STEP1))
      STTSST = HALF *  D7TPR(PS, V(STEP1), Y)
      IF (IV(MODEL) .EQ. 1) STTSST = -STTSST
      IF ( ABS(E + STTSST) * V(FUZZ) .GE.  ABS(E)) GO TO 360
C
C     ***  SWITCH MODELS  ***
C
         IV(MODEL) = 3 - IV(MODEL)
         IF (-2 .LT. L) GO TO 400
              IV(H) = -IABS(IV(H))
              IV(SUSED) = IV(SUSED) + 2
              L = IV(VSAVE)
              CALL V7CPY(NVSAVE, V(L), V)
              GO TO 160
C
 360  IF (-3 .LT. L) GO TO 400
C
C  ***  RECOMPUTE STEP WITH NEW RADIUS  ***
C
 370  V(RADIUS) = V(RADFAC) * V(DSTNRM)
      GO TO 160
C
C  ***  COMPUTE STEP OF LENGTH V(LMAXS) FOR SINGULAR CONVERGENCE TEST
C
 380  V(RADIUS) = V(LMAXS)
      GO TO 200
C
C  ***  CONVERGENCE OR FALSE CONVERGENCE  ***
C
 390  IV(CNVCOD) = L
      IF (V(F) .GE. V(F0)) GO TO 510
         IF (IV(XIRC) .EQ. 14) GO TO 510
              IV(XIRC) = 14
C
C. . . . . . . . . . . .  PROCESS ACCEPTABLE STEP  . . . . . . . . . . .
C
 400  IV(COVMAT) = 0
      IV(REGD) = 0
C
C  ***  SEE WHETHER TO SET V(RADFAC) BY GRADIENT TESTS  ***
C
      IF (IV(IRC) .NE. 3) GO TO 430
         STEP1 = IV(STEP)
         TEMP1 = IV(STLSTG)
         TEMP2 = IV(W)
C
C     ***  SET  TEMP1 = HESSIAN * STEP  FOR USE IN GRADIENT TESTS  ***
C
         HC1 = IV(HC)
         IF (HC1 .LE. 0) GO TO 410
              CALL  S7LVM(P, V(TEMP1), V(HC1), V(STEP1))
              GO TO 420
 410     RMAT1 = IV(RMAT)
         CALL  L7TVM(P, V(TEMP1), V(RMAT1), V(STEP1))
         CALL L7VML(P, V(TEMP1), V(RMAT1), V(TEMP1))
C
 420     IF (STPMOD .EQ. 1) GO TO 430
              S1 = IV(S)
              CALL  S7LVM(PS, V(TEMP2), V(S1), V(STEP1))
              CALL V2AXY(PS, V(TEMP1), ONE, V(TEMP2), V(TEMP1))
C
C  ***  SAVE OLD GRADIENT AND COMPUTE NEW ONE  ***
C
 430  IV(NGCALL) = IV(NGCALL) + 1
      G01 = IV(W)
      CALL V7CPY(P, V(G01), G)
      IV(1) = 2
      IV(TOOBIG) = 0
      GO TO 999
C
C  ***  INITIALIZATIONS -- G0 = G - G0, ETC.  ***
C
 440  G01 = IV(W)
      CALL V2AXY(P, V(G01), NEGONE, V(G01), G)
      STEP1 = IV(STEP)
      TEMP1 = IV(STLSTG)
      TEMP2 = IV(W)
      IF (IV(IRC) .NE. 3) GO TO 470
C
C  ***  SET V(RADFAC) BY GRADIENT TESTS  ***
C
C     ***  SET  TEMP1 = D**-1 * (HESSIAN * STEP  +  (G(X0) - G(X)))  ***
C
         K = TEMP1
         L = G01
         DO 450 I = 1, P
              V(K) = (V(K) - V(L)) / D(I)
              K = K + 1
              L = L + 1
 450          CONTINUE
C
C        ***  DO GRADIENT TESTS  ***
C
         IF ( V2NRM(P, V(TEMP1)) .LE. V(DGNORM) * V(TUNER4))  GO TO 460
              IF ( D7TPR(P, G, V(STEP1))
     1                  .GE. V(GTSTEP) * V(TUNER5))  GO TO 470
 460               V(RADFAC) = V(INCFAC)
C
C  ***  COMPUTE Y VECTOR NEEDED FOR UPDATING S  ***
C
 470  CALL V2AXY(PS, Y, NEGONE, Y, G)
C
C  ***  DETERMINE SIZING FACTOR V(SIZE)  ***
C
C     ***  SET TEMP1 = S * STEP  ***
      S1 = IV(S)
      CALL  S7LVM(PS, V(TEMP1), V(S1), V(STEP1))
C
      T1 =  ABS( D7TPR(PS, V(STEP1), V(TEMP1)))
      T =  ABS( D7TPR(PS, V(STEP1), Y))
      V(SIZE) = ONE
      IF (T .LT. T1) V(SIZE) = T / T1
C
C  ***  SET G0 TO WCHMTD CHOICE OF FLETCHER AND AL-BAALI  ***
C
      HC1 = IV(HC)
      IF (HC1 .LE. 0) GO TO 480
         CALL  S7LVM(PS, V(G01), V(HC1), V(STEP1))
         GO TO 490
C
 480  RMAT1 = IV(RMAT)
      CALL  L7TVM(PS, V(G01), V(RMAT1), V(STEP1))
      CALL L7VML(PS, V(G01), V(RMAT1), V(G01))
C
 490  CALL V2AXY(PS, V(G01), ONE, Y, V(G01))
C
C  ***  UPDATE S  ***
C
      CALL  S7LUP(V(S1), V(COSMIN), PS, V(SIZE), V(STEP1), V(TEMP1),
     1            V(TEMP2), V(G01), V(WSCALE), Y)
      IV(1) = 2
      GO TO 110
C
C. . . . . . . . . . . . . .  MISC. DETAILS  . . . . . . . . . . . . . .
C
C  ***  BAD PARAMETERS TO ASSESS  ***
C
 500  IV(1) = 64
      GO TO 999
C
C
C  ***  CONVERGENCE OBTAINED -- SEE WHETHER TO COMPUTE COVARIANCE  ***
C
 510  IF (IV(RDREQ) .EQ. 0) GO TO 600
      IF (IV(FDH) .NE. 0) GO TO 600
      IF (IV(CNVCOD) .GE. 7) GO TO 600
      IF (IV(REGD) .GT. 0) GO TO 600
      IF (IV(COVMAT) .GT. 0) GO TO 600
      IF (IABS(IV(COVREQ)) .GE. 3) GO TO 560
      IF (IV(RESTOR) .EQ. 0) IV(RESTOR) = 2
      GO TO 530
C
C  ***  COMPUTE FINITE-DIFFERENCE HESSIAN FOR COMPUTING COVARIANCE  ***
C
 520  IV(RESTOR) = 0
 530  CALL F7HES(D, G, I, IV, LIV, LV, P, V, X)
      GO TO (540, 550, 580), I
 540  IV(NFCOV) = IV(NFCOV) + 1
      IV(NFCALL) = IV(NFCALL) + 1
      IV(1) = 1
      GO TO 999
C
 550  IV(NGCOV) = IV(NGCOV) + 1
      IV(NGCALL) = IV(NGCALL) + 1
      IV(NFGCAL) = IV(NFCALL) + IV(NGCOV)
      IV(1) = 2
      GO TO 999
C
 560  H1 = IABS(IV(H))
      IV(H) = -H1
      PP1O2 = P * (P + 1) / 2
      RMAT1 = IV(RMAT)
      IF (RMAT1 .LE. 0) GO TO 570
           LMAT1 = IV(LMAT)
           CALL V7CPY(PP1O2, V(LMAT1), V(RMAT1))
           V(RCOND) = ZERO
           GO TO 590
 570  HC1 = IV(HC)
      IV(FDH) = H1
      CALL V7CPY(P*(P+1)/2, V(H1), V(HC1))
C
C  ***  COMPUTE CHOLESKY FACTOR OF FINITE-DIFFERENCE HESSIAN
C  ***  FOR USE IN CALLER*S COVARIANCE CALCULATION...
C
 580  LMAT1 = IV(LMAT)
      H1 = IV(FDH)
      IF (H1 .LE. 0) GO TO 600
      IF (IV(CNVCOD) .EQ. 70) GO TO 80
      CALL L7SRT(1, P, V(LMAT1), V(H1), I)
      IV(FDH) = -1
      V(RCOND) = ZERO
      IF (I .NE. 0) GO TO 600
C
 590  IV(FDH) = -1
      STEP1 = IV(STEP)
      T =  L7SVN(P, V(LMAT1), V(STEP1), V(STEP1))
      IF (T .LE. ZERO) GO TO 600
      T = T /  L7SVX(P, V(LMAT1), V(STEP1), V(STEP1))
      IF (T .GT.  R7MDC(4)) IV(FDH) = H1
      V(RCOND) = T
C
 600  IV(MODE) = 0
      IV(1) = IV(CNVCOD)
      IV(CNVCOD) = 0
      GO TO 999
C
C  ***  SPECIAL RETURN FOR MISSING HESSIAN INFORMATION -- BOTH
C  ***  IV(HC) .LE. 0 AND IV(RMAT) .LE. 0
C
 610  IV(1) = 1400
C
 999  RETURN
C
C  ***  LAST LINE OF G7LIT FOLLOWS  ***
      END
