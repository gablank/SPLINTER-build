#ifndef SPLINTER_MATLAB_H
#define SPLINTER_MATLAB_H

/*#define obj_ptr void * */
typedef void *obj_ptr;

#ifndef API
# ifdef _MSC_VER
#  define API __declspec(dllexport)
# else
#  define API
# endif
#endif

#ifdef __cplusplus
	extern "C"
	{
#endif
		/* 1 if the previous function call caused an error, 0 otherwise. */
		API int get_error();


		API obj_ptr datatable_init();

		API void datatable_add_samples(obj_ptr datatable_ptr, double *x, int n_samples, int x_dim);

		API void datatable_delete(obj_ptr datatable_ptr);


		API obj_ptr bspline_init(obj_ptr datatable_ptr, int type);

		API obj_ptr pspline_init(obj_ptr datatable_ptr, double lambda);

		API obj_ptr rbf_init(obj_ptr datatable_ptr, int type_index, int normalized);

		API obj_ptr polynomial_regression_init(obj_ptr datatable_ptr, int *degrees, int degrees_dim);


		API double eval(obj_ptr approximant, double *x, int x_dim);

		API double *eval_jacobian(obj_ptr approximant, double *x, int x_dim);

		API double *eval_hessian(obj_ptr approximant, double *x, int x_dim);

		API int get_num_variables(obj_ptr approximant);

		API void save(obj_ptr approximant, const char *filename);

		API void load(obj_ptr approximant, const char *filename);

		API void delete_approximant(obj_ptr approximant);

#ifdef __cplusplus
	}
#endif


#endif // SPLINTER_MATLAB_H