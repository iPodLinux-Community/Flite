;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                     ;;;
;;;                  Language Technologies Institute                    ;;;
;;;                     Carnegie Mellon University                      ;;;
;;;                         Copyright (c) 2000                          ;;;
;;;                        All Rights Reserved.                         ;;;
;;;                                                                     ;;;
;;; Permission is hereby granted, free of charge, to use and distribute ;;;
;;; this software and its documentation without restriction, including  ;;;
;;; without limitation the rights to use, copy, modify, merge, publish, ;;;
;;; distribute, sublicense, and/or sell copies of this work, and to     ;;;
;;; permit persons to whom this work is furnished to do so, subject to  ;;;
;;; the following conditions:                                           ;;;
;;;  1. The code must retain the above copyright notice, this list of   ;;;
;;;     conditions and the following disclaimer.                        ;;;
;;;  2. Any modifications must be clearly marked as such.               ;;;
;;;  3. Original authors' names are not deleted.                        ;;;
;;;  4. The authors' names are not used to endorse or promote products  ;;;
;;;     derived from this software without specific prior written       ;;;
;;;     permission.                                                     ;;;
;;;                                                                     ;;;
;;; CARNEGIE MELLON UNIVERSITY AND THE CONTRIBUTORS TO THIS WORK        ;;;
;;; DISCLAIM ALL WARRANTIES WITH REGARD TO THIS SOFTWARE, INCLUDING     ;;;
;;; ALL IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS, IN NO EVENT  ;;;
;;; SHALL CARNEGIE MELLON UNIVERSITY NOR THE CONTRIBUTORS BE LIABLE     ;;;
;;; FOR ANY SPECIAL, INDIRECT OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES   ;;;
;;; WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN  ;;;
;;; AN ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION,         ;;;
;;; ARISING OUT OF OR IN CONNECTION WITH THE USE OR PERFORMANCE OF      ;;;
;;; THIS SOFTWARE.                                                      ;;;
;;;                                                                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;             Author: Alan W Black (awb@cs.cmu.edu)                   ;;;
;;;               Date: December 2000                                   ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                     ;;;
;;; Convert a phoneset to a C compilable structure                      ;;;
;;;                                                                     ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(defvar featval_ids nil)

(define (phonesettoC name phonesetdef silence odir)
  "(phonesettoC name phonesetdef ODIR)
Convert a Phoneset definition to a C structure in ODIR/NAME_phoneset.c."
  (let 
    ((ofdc (fopen (path-append odir (string-append name "_phoneset.c")) "w"))
     (i 0))
    (format ofdc "/*******************************************************/\n")
    (format ofdc "/**  Autogenerated phoneset trees for %s    */\n" name)
    (format ofdc "/*******************************************************/\n")
    (format ofdc "\n")
    (format ofdc "#include \"cst_string.h\"\n")
    (format ofdc "#include \"cst_phoneset.h\"\n")
    (format ofdc "extern const cst_phoneset %s_phoneset;\n" name)

    (set! featval_ids nil)
    (format ofdc "\n\n")
    ;;; feature names
    (format ofdc "static const char * const %s_featnames[] = {\n" name)
    (mapcar
     (lambda (fn) (format ofdc " \"%s\",\n" fn))
     (mapcar car (caddr phonesetdef)))
    (format ofdc " NULL };\n\n")

    ;;; Phone names
    (format ofdc "static const char * const %s_phonenames[] = {\n" name)
    (mapcar
     (lambda (pn) (format ofdc " \"%s\",\n" pn))
     (mapcar car (caddr (cdr phonesetdef))))
    (format ofdc " NULL };\n\n")
    (set! num_phones (length (caddr (cdr phonesetdef))))

    ;;; Feature table (do values afterwards)
    (set! i 0)
    (mapcar
     (lambda (pdef) 
       (format ofdc "static const int %s_fv_%03d[] = { " name i)
       (mapcar
	(lambda (fv)
	  (format ofdc "%d, " (phonesettoC_featval_id fv)))
	(cdr pdef))
       (set! i (+ i 1))
       (format ofdc "  -1 };\n"))
     (caddr (cdr phonesetdef)))
    (format ofdc "static const int %s_fv_%03d[] = { 0 };\n\n" name i)

    (set! i 0)
    (format ofdc "static const int * const %s_fvtable[] = {\n" name )
    (mapcar
     (lambda (pdef) 
       (format ofdc "  %s_fv_%03d, \n" name i)
       (set! i (+ i 1)))
     (caddr (cdr phonesetdef)))
    (format ofdc " %s_fv_%03d };\n\n" name i)
    
    ;;; Feature values
    (set! i 0)
    (mapcar
     (lambda (fv) 
       (format ofdc "DEF_STATIC_CONST_VAL_STRING(featval_%d,\"%s\");\n" i fv)
       (set! i (+ i 1)))
     (mapcar car (reverse featval_ids)))
    (format ofdc "\n")

    (format ofdc "static const cst_val * const %s_featvals[] = {\n" name)
    (set! i 0)
    (mapcar
     (lambda (fv) 
       (format ofdc " (cst_val *)&featval_%d,\n" i)
       (set! i (+ i 1)))
     (mapcar car (reverse featval_ids)))
    (format ofdc " NULL };\n\n")

    (format ofdc "const cst_phoneset %s_phoneset = {\n" name)
    (format ofdc "  \"%s\",\n" name)
    (format ofdc "  %s_featnames,\n" name)
    (format ofdc "  %s_featvals,\n" name)
    (format ofdc "  %s_phonenames,\n" name)
    (format ofdc "  \"%s\",\n" silence)
    (format ofdc "  %d,\n" num_phones)
    (format ofdc "  %s_fvtable\n" name)
    (format ofdc "};\n")

    (fclose ofdc)
    ))

(define (phonesettoC_featval_id f)
  (let ((fn (assoc_string f featval_ids)))
    (cond
     (fn
      (cadr fn))
     (t
      (set! featval_ids
	    (cons (list f (length featval_ids))
		  featval_ids))
      (phonesettoC_featval_id f)))))

(provide 'make_phoneset)