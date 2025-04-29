#' Clean up confusion matrix and associated stats
#' 
#' Cleans up the confusion matrix from a caret/ranger model fit:
#' - If class names are numeric:
#'   - include only the number in the confusion matrix and sort numerically
#'   - change the labels to `Class <number>` in the byClass table and sort
#'     numerically
#' - Round the byClass table to 4 digits, which is more than plenty!
#' - Optionally add rows for AUC and F1 to the byClass table
#' - If the model is not a 2x2, drop Mcnemar's Test P-Value
#' 
#' Print the resulting table with `print(fit$confuse, mode = 'everything')`
#' 
#' @param fit A ranger model object
#' @param auc If TRUE, add AUC to the byClass table
#' @param f1 If TRUE, add F1 to the byClass table
#' @returns A new model object with the confusion matrix cleaned up
#' @export


unconfuse <- function(fit, auc = TRUE, f1 = TRUE) {
   
   
   classes <- colnames(fit$confuse$table)
   if(length(grep('\\d$', classes)) == length(classes)) {                        # if class names all end in numbers
      n <- as.numeric(sub('[a-zA-Z]*(\\d+)$', '\\1', classes))                   #    pull the numbers
      s <- order(n)
      
      colnames(fit$confuse$table) <- n                                           #    use numbers for names in confusion matrix
      rownames(fit$confuse$table) <- n
      fit$confuse$table <- fit$confuse$table[s, s]                               #    and sort it numerically
   
      rownames(fit$confuse$byClass) <- paste0('Class ', n)                       #    use numbers in byClass table
      fit$confuse$byClass <- fit$confuse$byClass[s, ]
   }
   
   fit$confuse$byClass <- round(fit$confuse$byClass, 4)
   
   # if(auc)
   #    fit$confuse$byClass <- cbind(fit$confuse$byClass, AUC = aucs(fit))
   # 
   # 
   # print(fit$confuse, mode = 'everything', digits = 3)           Hmmmmmmm................
   # # they include F1
   # # but it doesn't like me adding AUC
   # # 
   # 
   # 
   fit
}