#ifndef included_pIBStandardForceGen
#define included_pIBStandardForceGen

// Filename: pIBStandardForceGen.h
// Last modified: <18.Jan.2007 15:47:37 boyce@bigboy.nyconnect.com>
// Created on 14 Jul 2004 by Boyce Griffith (boyce@trasnaform.speakeasy.net)

/////////////////////////////// INCLUDES /////////////////////////////////////

// IBAMR INCLUDES
#include <ibamr/IBLagrangianForceStrategy.h>
#include <ibamr/LDataManager.h>
#include <ibamr/LNodeLevelData.h>

// SAMRAI INCLUDES
#include <PatchHierarchy.h>
#include <tbox/Database.h>
#include <tbox/Pointer.h>

// PETSc INCLUDES
#include <petscmat.h>

// C++ STDLIB INCLUDES
#include <vector>

/////////////////////////////// CLASS DEFINITION /////////////////////////////

namespace IBAMR
{
/*!
 * @brief Class pIBStandardForceGen computes the force generated by a
 * collection of linear springs.
 */
class pIBStandardForceGen
    : public IBLagrangianForceStrategy
{
public:
    /*!
     * @brief Default constructor.
     */
    pIBStandardForceGen(
        SAMRAI::tbox::Pointer<SAMRAI::tbox::Database> input_db=NULL);

    /*!
     * @brief Destructor.
     */
    ~pIBStandardForceGen();

    /*!
     * @brief Setup the data needed to compute spring forces on the
     * specified level of the patch hierarchy.
     */
    void initializeLevelData(
        const SAMRAI::tbox::Pointer<SAMRAI::hier::PatchHierarchy<NDIM> > hierarchy,
        const int level_number,
        const double init_data_time,
        const bool initial_time,
        const LDataManager* const lag_manager);

    /*!
     * @brief Compute the force generated by a collection of linear
     * springs (i.e. springs with zero resting lengths).
     */
    void computeLagrangianForce(
        SAMRAI::tbox::Pointer<LNodeLevelData> F_data,
        SAMRAI::tbox::Pointer<LNodeLevelData> X_data,
        const SAMRAI::tbox::Pointer<SAMRAI::hier::PatchHierarchy<NDIM> > hierarchy,
        const int level_number,
        const double data_time,
        const LDataManager* const lag_manager);

private:
    /*!
     * @brief Copy constructor.
     *
     * NOTE: This constructor is not implemented and should not be
     * used.
     *
     * @param from The value to copy to this object.
     */
    pIBStandardForceGen(
        const pIBStandardForceGen& from);

    /*!
     * @brief Assignment operator.
     *
     * NOTE: This operator is not implemented and should not be used.
     *
     * @param that The value to assign to this object.
     *
     * @return A reference to this object.
     */
    pIBStandardForceGen& operator=(
        const pIBStandardForceGen& that);

    /*
     * Data maintained separately for each level of the patch
     * hierarchy.
     */
    std::vector<Mat> d_L_mats;
    std::vector<std::vector<int> > d_local_src_ids;
    std::vector<std::vector<double> > d_stiffnesses;
    std::vector<bool> d_level_initialized;
};
}// namespace IBAMR

/////////////////////////////// INLINE ///////////////////////////////////////

//#include <ibamr/pIBStandardForceGen.I>

//////////////////////////////////////////////////////////////////////////////

#endif //#ifndef included_pIBStandardForceGen